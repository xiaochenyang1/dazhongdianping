package com.tuowei.dazhongdianping.module.adpromo.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.adpromo.mapper.AdMapper;
import com.tuowei.dazhongdianping.module.adpromo.model.AdCampaignRow;
import com.tuowei.dazhongdianping.module.adpromo.model.AdReportRow;
import com.tuowei.dazhongdianping.module.adpromo.model.request.AdCampaignSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 商家端广告投放：创建/编辑/暂停恢复自家门店的推广计划。 */
@Service
public class MerchantAdService {

    private final AdMapper mapper;
    private final AdPresenter presenter;
    private final MerchantAuthorizationService authorizationService;

    public MerchantAdService(AdMapper mapper, AdPresenter presenter,
                             MerchantAuthorizationService authorizationService) {
        this.mapper = mapper;
        this.presenter = presenter;
        this.authorizationService = authorizationService;
    }

    public PageResult<Map<String, Object>> campaigns(Integer page, Integer pageSize) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "ad:view");
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countMerchantCampaigns(session.merchantId(), region);
        List<Map<String, Object>> list = presenter.campaigns(
                mapper.selectMerchantCampaigns(session.merchantId(), region, s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> create(AdCampaignSaveRequest req) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "ad:manage");
        String region = region();
        Long shopMerchant = mapper.selectShopMerchantId(req.shopId(), region);
        if (shopMerchant == null || !shopMerchant.equals(session.merchantId())) {
            throw new NotFoundException("门店不存在");
        }
        AdCampaignRow row = fromRequest(req);
        row.setRegion(region);
        row.setMerchantId(session.merchantId());
        mapper.insertCampaign(row);
        return presenter.campaign(mapper.selectMerchantCampaign(row.getId(), session.merchantId(), region));
    }

    @Transactional
    public Map<String, Object> update(Long id, AdCampaignSaveRequest req) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "ad:manage");
        String region = region();
        AdCampaignRow existing = mapper.selectMerchantCampaign(id, session.merchantId(), region);
        if (existing == null) {
            throw new NotFoundException("广告投放不存在");
        }
        Long shopMerchant = mapper.selectShopMerchantId(req.shopId(), region);
        if (shopMerchant == null || !shopMerchant.equals(session.merchantId())) {
            throw new NotFoundException("门店不存在");
        }
        AdCampaignRow row = fromRequest(req);
        row.setId(id);
        row.setMerchantId(session.merchantId());
        mapper.updateCampaign(row);
        return presenter.campaign(mapper.selectMerchantCampaign(id, session.merchantId(), region));
    }

    /** 暂停(2)或恢复(1)投放。 */
    @Transactional
    public Map<String, Object> setStatus(Long id, int status) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "ad:manage");
        String region = region();
        AdCampaignRow existing = mapper.selectMerchantCampaign(id, session.merchantId(), region);
        if (existing == null) {
            throw new NotFoundException("广告投放不存在");
        }
        if (mapper.updateStatus(id, session.merchantId(), status) == 0) {
            throw new ConflictException("广告投放状态更新失败");
        }
        return presenter.campaign(mapper.selectMerchantCampaign(id, session.merchantId(), region));
    }

    /** 门店投放报表。只读点击日志与已记账花费，不改变计费。 */
    public Map<String, Object> report(Long shopId) {
        MerchantSession session = requireSession();
        authorizationService.requireShop(session, "ad:view", shopId);
        List<Map<String, Object>> campaigns = mapper.selectShopReport(session.merchantId(), shopId, region())
                .stream().map(this::reportMap).toList();
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("shopId", shopId);
        body.put("campaigns", campaigns);
        return body;
    }

    private Map<String, Object> reportMap(AdReportRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("shopId", row.getShopId());
        body.put("name", row.getName());
        body.put("status", row.getStatus());
        body.put("auditStatus", row.getAuditStatus());
        body.put("totalSpent", row.getTotalSpent() == null ? BigDecimal.ZERO : row.getTotalSpent());
        body.put("spentToday", row.getSpentToday() == null ? BigDecimal.ZERO : row.getSpentToday());
        body.put("clickCount", row.getClickCount() == null ? 0L : row.getClickCount());
        body.put("clickCost", row.getClickCost() == null ? BigDecimal.ZERO : row.getClickCost());
        return body;
    }

    private AdCampaignRow fromRequest(AdCampaignSaveRequest r) {
        AdCampaignRow row = new AdCampaignRow();
        row.setShopId(r.shopId());
        row.setName(r.name());
        row.setSlotType(r.slotType());
        row.setKeyword(r.keyword() == null ? "" : r.keyword().trim().toLowerCase());
        row.setBidCpc(r.bidCpc());
        row.setDailyBudget(r.dailyBudget());
        return row;
    }

    private MerchantSession requireSession() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
