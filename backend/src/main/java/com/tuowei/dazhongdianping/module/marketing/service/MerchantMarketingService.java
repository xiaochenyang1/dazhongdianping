package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingMapper;
import com.tuowei.dazhongdianping.module.marketing.model.CouponTemplateRow;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyCampaignRow;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillEventRow;
import com.tuowei.dazhongdianping.module.marketing.model.request.GroupBuySaveRequest;
import com.tuowei.dazhongdianping.module.marketing.model.request.MerchantCouponCreateRequest;
import com.tuowei.dazhongdianping.module.marketing.model.request.SeckillSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 商家营销：自建券、秒杀、拼团，创建后待平台审核。 */
@Service
public class MerchantMarketingService {

    private final MarketingMapper couponMapper;
    private final MarketingCampaignMapper campaignMapper;
    private final MerchantAuthorizationService authorizationService;

    public MerchantMarketingService(
            MarketingMapper couponMapper,
            MarketingCampaignMapper campaignMapper,
            MerchantAuthorizationService authorizationService) {
        this.couponMapper = couponMapper;
        this.campaignMapper = campaignMapper;
        this.authorizationService = authorizationService;
    }

    public List<Map<String, Object>> coupons() {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "marketing:view");
        return couponMapper.selectMerchantTemplates(session.merchantId(), region()).stream()
                .map(this::couponMap)
                .toList();
    }

    @Transactional
    public Map<String, Object> createCoupon(MerchantCouponCreateRequest request) {
        MerchantSession session = requireSession();
        authorizationService.requireShop(session, "marketing:manage", request.shopId());
        String region = region();
        CouponTemplateRow row = new CouponTemplateRow();
        row.setRegion(region);
        row.setName(request.name().trim());
        row.setType(request.type());
        row.setThresholdAmount(money(request.type() == 2 ? BigDecimal.ZERO : request.thresholdAmount()));
        row.setDiscountAmount(money(request.discountAmount()));
        row.setCurrency(currency(request.shopId(), region));
        row.setShopId(request.shopId());
        row.setMerchantId(session.merchantId());
        row.setTotalQuantity(request.totalQuantity());
        row.setPerUserLimit(request.perUserLimit());
        row.setValidDays(request.validDays());
        couponMapper.insertMerchantTemplate(row);
        CouponTemplateRow saved = couponMapper.selectTemplate(row.getId(), region);
        return couponMap(saved);
    }

    public List<Map<String, Object>> seckills(Long shopId) {
        MerchantSession session = requireSession();
        authorizationService.requireShop(session, "marketing:view", shopId);
        return campaignMapper.selectMerchantSeckills(session.merchantId(), shopId, region()).stream()
                .map(this::seckillMap)
                .toList();
    }

    @Transactional
    public Map<String, Object> createSeckill(SeckillSaveRequest request) {
        MerchantSession session = requireSession();
        requireWindow(request.startAt(), request.endAt());
        authorizationService.requireShop(session, "marketing:manage", request.shopId());
        String region = region();
        requireDeal(request.dealId(), request.shopId(), session.merchantId(), region);
        SeckillEventRow row = new SeckillEventRow();
        row.setRegion(region);
        row.setShopId(request.shopId());
        row.setMerchantId(session.merchantId());
        row.setDealId(request.dealId());
        row.setTitle(request.title().trim());
        row.setSeckillPrice(money(request.seckillPrice()));
        row.setCurrency(currency(request.shopId(), region));
        row.setStock(request.stock());
        row.setStartAt(request.startAt());
        row.setEndAt(request.endAt());
        campaignMapper.insertSeckill(row);
        return seckillMap(campaignMapper.selectSeckill(row.getId(), region));
    }

    public List<Map<String, Object>> groupBuys(Long shopId) {
        MerchantSession session = requireSession();
        authorizationService.requireShop(session, "marketing:view", shopId);
        return campaignMapper.selectMerchantGroups(session.merchantId(), shopId, region()).stream()
                .map(this::groupMap)
                .toList();
    }

    @Transactional
    public Map<String, Object> createGroupBuy(GroupBuySaveRequest request) {
        MerchantSession session = requireSession();
        requireWindow(request.startAt(), request.endAt());
        authorizationService.requireShop(session, "marketing:manage", request.shopId());
        String region = region();
        requireDeal(request.dealId(), request.shopId(), session.merchantId(), region);
        GroupBuyCampaignRow row = new GroupBuyCampaignRow();
        row.setRegion(region);
        row.setShopId(request.shopId());
        row.setMerchantId(session.merchantId());
        row.setDealId(request.dealId());
        row.setTitle(request.title().trim());
        row.setGroupPrice(money(request.groupPrice()));
        row.setCurrency(currency(request.shopId(), region));
        row.setGroupSize(request.groupSize());
        row.setStartAt(request.startAt());
        row.setEndAt(request.endAt());
        campaignMapper.insertGroup(row);
        return groupMap(campaignMapper.selectGroup(row.getId(), region));
    }

    private void requireDeal(Long dealId, Long shopId, Long merchantId, String region) {
        if (campaignMapper.countOwnedDeal(dealId, shopId, merchantId, region) != 1) {
            throw new IllegalArgumentException("套餐不存在或不属于该门店");
        }
    }

    private void requireWindow(java.time.LocalDateTime startAt, java.time.LocalDateTime endAt) {
        if (startAt == null || endAt == null || !endAt.isAfter(startAt)) {
            throw new IllegalArgumentException("结束时间必须晚于开始时间");
        }
    }

    private String currency(Long shopId, String region) {
        String currency = campaignMapper.selectShopCurrency(shopId, region);
        if (currency == null || currency.isBlank()) {
            return "EU".equals(region) ? "EUR" : "CNY";
        }
        return currency;
    }

    private Map<String, Object> couponMap(CouponTemplateRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("name", row.getName());
        body.put("type", row.getType());
        body.put("thresholdAmount", row.getThresholdAmount());
        body.put("discountAmount", row.getDiscountAmount());
        body.put("currency", row.getCurrency());
        body.put("shopId", row.getShopId());
        body.put("merchantId", row.getMerchantId());
        body.put("totalQuantity", row.getTotalQuantity());
        body.put("perUserLimit", row.getPerUserLimit());
        body.put("validDays", row.getValidDays());
        body.put("status", row.getStatus());
        body.put("auditStatus", row.getAuditStatus());
        body.put("rejectReason", row.getRejectReason() == null ? "" : row.getRejectReason());
        return body;
    }

    private Map<String, Object> seckillMap(SeckillEventRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("shopId", row.getShopId());
        body.put("dealId", row.getDealId());
        body.put("title", row.getTitle());
        body.put("seckillPrice", row.getSeckillPrice());
        body.put("currency", row.getCurrency());
        body.put("stock", row.getStock());
        body.put("sold", row.getSold());
        body.put("startAt", row.getStartAt());
        body.put("endAt", row.getEndAt());
        body.put("status", row.getStatus());
        body.put("auditStatus", row.getAuditStatus());
        body.put("rejectReason", row.getRejectReason() == null ? "" : row.getRejectReason());
        return body;
    }

    private Map<String, Object> groupMap(GroupBuyCampaignRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("shopId", row.getShopId());
        body.put("dealId", row.getDealId());
        body.put("title", row.getTitle());
        body.put("groupPrice", row.getGroupPrice());
        body.put("currency", row.getCurrency());
        body.put("groupSize", row.getGroupSize());
        body.put("startAt", row.getStartAt());
        body.put("endAt", row.getEndAt());
        body.put("status", row.getStatus());
        body.put("auditStatus", row.getAuditStatus());
        body.put("rejectReason", row.getRejectReason() == null ? "" : row.getRejectReason());
        return body;
    }

    private BigDecimal money(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
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
