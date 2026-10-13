package com.tuowei.dazhongdianping.module.adpromo.service;

import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.adpromo.mapper.AdMapper;
import com.tuowei.dazhongdianping.module.adpromo.model.AdCampaignRow;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/** C端广告投放：固定坑位召回 + 点击计费。 */
@Service
public class AdService {

    private final AdMapper mapper;
    private final AdPresenter presenter;
    private final AdClickDeduplicator deduplicator;

    public AdService(AdMapper mapper, AdPresenter presenter, AdClickDeduplicator deduplicator) {
        this.mapper = mapper;
        this.presenter = presenter;
        this.deduplicator = deduplicator;
    }

    /** 固定广告位召回。slotType 1=搜索(可带 keyword) 2=首页/列表。 */
    public List<Map<String, Object>> serve(Integer slotType, String keyword, Integer limit) {
        int type = slotType == null ? 1 : slotType;
        int n = limit == null ? 3 : Math.min(10, Math.max(1, limit));
        String kw = keyword == null ? null : keyword.trim().toLowerCase();
        return mapper.selectServing(region(), type, kw, n).stream().map(presenter::serving).toList();
    }

    /**
     * 记录一次广告点击并按 CPC 计费。
     * 同一访客（登录 userId / 匿名 IP）对同一广告在去重窗口内只计费一次；超预算不扣费。
     */
    @Transactional
    public Map<String, Object> click(Long campaignId, String clientIp) {
        String region = region();
        AdCampaignRow c = mapper.selectCampaign(campaignId, region);
        if (c == null) {
            return Map.of("charged", false);
        }
        UserSession u = UserSessionContext.get();
        long userId = u == null ? 0L : u.userId();
        Optional<AdClickDeduplicator.Acquisition> acquisition =
                deduplicator.acquire(region, campaignId, userId, clientIp);
        if (acquisition.isEmpty()) {
            return Map.of("charged", false, "shopId", c.getShopId());
        }
        AdClickDeduplicator.Acquisition claim = acquisition.get();
        boolean synchronizationActive = TransactionSynchronizationManager.isSynchronizationActive();
        if (synchronizationActive) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCompletion(int status) {
                    if (status != STATUS_COMMITTED) {
                        deduplicator.release(claim);
                    }
                }
            });
        }
        try {
            boolean charged = mapper.chargeClick(campaignId, region) == 1;
            if (charged) {
                mapper.insertClickLog(campaignId, region, c.getShopId(), c.getBidCpc());
            }
            return Map.of("charged", charged, "shopId", c.getShopId());
        } catch (RuntimeException | Error ex) {
            if (!synchronizationActive) {
                deduplicator.release(claim);
            }
            throw ex;
        }
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
