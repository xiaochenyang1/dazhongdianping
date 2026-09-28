package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingMapper;
import com.tuowei.dazhongdianping.module.marketing.model.CouponTemplateRow;
import com.tuowei.dazhongdianping.module.marketing.model.request.CampaignAuditRequest;
import com.tuowei.dazhongdianping.module.marketing.model.request.CouponTemplateSaveRequest;
import com.tuowei.dazhongdianping.module.marketing.model.response.CouponTemplateResponse;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Admin/运营侧优惠券模板管理，按当前区域读写。 */
@Service
public class AdminMarketingService {

    private final MarketingMapper mapper;

    public AdminMarketingService(MarketingMapper mapper) {
        this.mapper = mapper;
    }

    public PageResult<CouponTemplateResponse> templates(Integer status, Integer page, Integer pageSize) {
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countTemplates(region, status);
        List<CouponTemplateResponse> list = mapper.selectTemplates(region, status, s, (p - 1) * s)
                .stream().map(this::toResponse).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public CouponTemplateResponse create(CouponTemplateSaveRequest request) {
        CouponTemplateRow row = fromRequest(request);
        row.setRegion(region());
        mapper.insertTemplate(row);
        return toResponse(mapper.selectTemplate(row.getId(), row.getRegion()));
    }

    @Transactional
    public CouponTemplateResponse update(Long id, CouponTemplateSaveRequest request) {
        String region = region();
        CouponTemplateRow existing = mapper.selectTemplate(id, region);
        if (existing == null) {
            throw new NotFoundException("优惠券模板不存在");
        }
        CouponTemplateRow row = fromRequest(request);
        row.setId(id);
        row.setRegion(region);
        mapper.updateTemplate(row);
        return toResponse(mapper.selectTemplate(id, region));
    }

    @Transactional
    public Map<String, Object> audit(Long id, CampaignAuditRequest request) {
        String region = region();
        CouponTemplateRow existing = mapper.selectTemplate(id, region);
        if (existing == null) {
            throw new NotFoundException("优惠券模板不存在");
        }
        int auditStatus = Boolean.TRUE.equals(request.approve()) ? 2 : 3;
        String reason = "";
        if (!Boolean.TRUE.equals(request.approve())) {
            if (request.reason() == null || request.reason().isBlank()) {
                throw new IllegalArgumentException("驳回需填写原因");
            }
            reason = request.reason().trim();
        }
        if (mapper.updateTemplateAudit(id, region, auditStatus, reason) == 0) {
            throw new ConflictException("优惠券当前状态不可审核");
        }
        CouponTemplateRow saved = mapper.selectTemplate(id, region);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", saved.getId());
        body.put("name", saved.getName());
        body.put("auditStatus", saved.getAuditStatus());
        body.put("rejectReason", saved.getRejectReason() == null ? "" : saved.getRejectReason());
        body.put("status", saved.getStatus());
        return body;
    }

    private CouponTemplateRow fromRequest(CouponTemplateSaveRequest r) {
        CouponTemplateRow row = new CouponTemplateRow();
        row.setName(r.name());
        row.setType(r.type());
        row.setThresholdAmount(r.type() == 2 ? java.math.BigDecimal.ZERO : r.thresholdAmount());
        row.setDiscountAmount(r.discountAmount());
        row.setCurrency(r.currency().toUpperCase());
        row.setShopId(r.shopId());
        row.setTotalQuantity(r.totalQuantity());
        row.setPerUserLimit(r.perUserLimit());
        row.setValidDays(r.validDays());
        row.setClaimStart(r.claimStart());
        row.setClaimEnd(r.claimEnd());
        row.setStatus(r.status());
        return row;
    }

    private CouponTemplateResponse toResponse(CouponTemplateRow t) {
        return new CouponTemplateResponse(
                t.getId(), t.getRegion(), t.getName(), t.getType(),
                t.getType() != null && t.getType() == 2 ? "新客立减" : "满减券",
                t.getThresholdAmount(), t.getDiscountAmount(), t.getCurrency(), t.getShopId(),
                t.getTotalQuantity(), t.getClaimedQuantity(), t.getPerUserLimit(), t.getValidDays(),
                t.getClaimStart(), t.getClaimEnd(), t.getStatus());
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
