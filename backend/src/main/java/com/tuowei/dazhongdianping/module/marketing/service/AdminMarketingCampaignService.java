package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyCampaignRow;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillEventRow;
import com.tuowei.dazhongdianping.module.marketing.model.request.CampaignAuditRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 平台审核商家秒杀与拼团。 */
@Service
public class AdminMarketingCampaignService {

    private final MarketingCampaignMapper mapper;

    public AdminMarketingCampaignService(MarketingCampaignMapper mapper) {
        this.mapper = mapper;
    }

    public List<Map<String, Object>> listSeckills() {
        return mapper.selectAdminSeckills(region()).stream().map(this::seckill).toList();
    }

    public List<Map<String, Object>> listGroups() {
        return mapper.selectAdminGroups(region()).stream().map(this::group).toList();
    }

    @Transactional
    public Map<String, Object> auditSeckill(Long id, CampaignAuditRequest request) {
        String region = region();
        SeckillEventRow existing = mapper.selectSeckill(id, region);
        if (existing == null) {
            throw new NotFoundException("秒杀活动不存在");
        }
        AuditDecision decision = decision(request);
        if (mapper.updateSeckillAudit(id, region, decision.status(), decision.reason()) == 0) {
            throw new ConflictException("秒杀活动当前状态不可审核");
        }
        SeckillEventRow saved = mapper.selectSeckill(id, region);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", saved.getId());
        body.put("title", saved.getTitle());
        body.put("auditStatus", saved.getAuditStatus());
        body.put("rejectReason", saved.getRejectReason() == null ? "" : saved.getRejectReason());
        body.put("status", saved.getStatus());
        return body;
    }

    @Transactional
    public Map<String, Object> auditGroupBuy(Long id, CampaignAuditRequest request) {
        String region = region();
        GroupBuyCampaignRow existing = mapper.selectGroup(id, region);
        if (existing == null) {
            throw new NotFoundException("拼团活动不存在");
        }
        AuditDecision decision = decision(request);
        if (mapper.updateGroupAudit(id, region, decision.status(), decision.reason()) == 0) {
            throw new ConflictException("拼团活动当前状态不可审核");
        }
        GroupBuyCampaignRow saved = mapper.selectGroup(id, region);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", saved.getId());
        body.put("title", saved.getTitle());
        body.put("auditStatus", saved.getAuditStatus());
        body.put("rejectReason", saved.getRejectReason() == null ? "" : saved.getRejectReason());
        body.put("status", saved.getStatus());
        return body;
    }

    private Map<String, Object> seckill(SeckillEventRow row) {
        Map<String, Object> body = campaign(row.getId(), row.getShopId(), row.getTitle(), row.getAuditStatus(),
                row.getStatus(), row.getRejectReason(), row.getCurrency());
        body.put("seckillPrice", row.getSeckillPrice());
        body.put("stock", row.getStock());
        body.put("sold", row.getSold());
        body.put("startAt", row.getStartAt());
        body.put("endAt", row.getEndAt());
        return body;
    }

    private Map<String, Object> group(GroupBuyCampaignRow row) {
        Map<String, Object> body = campaign(row.getId(), row.getShopId(), row.getTitle(), row.getAuditStatus(),
                row.getStatus(), row.getRejectReason(), row.getCurrency());
        body.put("groupPrice", row.getGroupPrice());
        body.put("groupSize", row.getGroupSize());
        body.put("startAt", row.getStartAt());
        body.put("endAt", row.getEndAt());
        return body;
    }

    private Map<String, Object> campaign(
            Long id, Long shopId, String title, Integer auditStatus, Integer status, String rejectReason, String currency) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", id);
        body.put("shopId", shopId);
        body.put("title", title);
        body.put("auditStatus", auditStatus);
        body.put("status", status);
        body.put("rejectReason", rejectReason == null ? "" : rejectReason);
        body.put("currency", currency);
        return body;
    }

    private AuditDecision decision(CampaignAuditRequest request) {
        if (Boolean.TRUE.equals(request.approve())) {
            return new AuditDecision(2, "");
        }
        if (request.reason() == null || request.reason().isBlank()) {
            throw new IllegalArgumentException("驳回需填写原因");
        }
        return new AuditDecision(3, request.reason().trim());
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private record AuditDecision(int status, String reason) {
    }
}
