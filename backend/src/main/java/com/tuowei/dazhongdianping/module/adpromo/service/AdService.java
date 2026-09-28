package com.tuowei.dazhongdianping.module.adpromo.service;

import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.adpromo.mapper.AdMapper;
import com.tuowei.dazhongdianping.module.adpromo.model.AdCampaignRow;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C端广告投放：固定坑位召回 + 点击计费。 */
@Service
public class AdService {

    private final AdMapper mapper;
    private final AdPresenter presenter;

    public AdService(AdMapper mapper, AdPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    /** 固定广告位召回。slotType 1=搜索(可带 keyword) 2=首页/列表。 */
    public List<Map<String, Object>> serve(Integer slotType, String keyword, Integer limit) {
        int type = slotType == null ? 1 : slotType;
        int n = limit == null ? 3 : Math.min(10, Math.max(1, limit));
        String kw = keyword == null ? null : keyword.trim().toLowerCase();
        return mapper.selectServing(region(), type, kw, n).stream().map(presenter::serving).toList();
    }

    /** 记录一次广告点击并按 CPC 计费（超预算则只记展示、不重复扣费）。 */
    @Transactional
    public Map<String, Object> click(Long campaignId) {
        String region = region();
        AdCampaignRow c = mapper.selectCampaign(campaignId, region);
        if (c == null) {
            return Map.of("charged", false);
        }
        UserSession u = UserSessionContext.get();
        long userId = u == null ? 0L : u.userId();
        boolean charged = mapper.chargeClick(campaignId, region) == 1;
        if (charged) {
            mapper.insertClickLog(campaignId, region, c.getShopId(), userId, c.getBidCpc());
        }
        return Map.of("charged", charged, "shopId", c.getShopId());
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
