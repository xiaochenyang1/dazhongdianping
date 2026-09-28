package com.tuowei.dazhongdianping.module.adpromo.service;

import com.tuowei.dazhongdianping.module.adpromo.model.AdCampaignRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

/** 广告投放行到响应体的统一映射。 */
@Component
public class AdPresenter {

    /** 商家/平台管理视角：完整投放信息。 */
    public Map<String, Object> campaign(AdCampaignRow c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", c.getId());
        m.put("shopId", c.getShopId());
        m.put("shopName", c.getShopName() == null ? "" : c.getShopName());
        m.put("name", c.getName());
        m.put("slotType", c.getSlotType());
        m.put("slotTypeText", slotText(c.getSlotType()));
        m.put("keyword", c.getKeyword() == null ? "" : c.getKeyword());
        m.put("bidCpc", c.getBidCpc());
        m.put("dailyBudget", c.getDailyBudget());
        m.put("spentToday", c.getSpentToday());
        m.put("totalSpent", c.getTotalSpent());
        m.put("status", c.getStatus());
        m.put("statusText", statusText(c.getStatus()));
        m.put("auditStatus", c.getAuditStatus());
        m.put("auditStatusText", auditText(c.getAuditStatus()));
        m.put("rejectReason", c.getRejectReason() == null ? "" : c.getRejectReason());
        m.put("createdAt", c.getCreatedAt());
        m.put("updatedAt", c.getUpdatedAt());
        return m;
    }

    public List<Map<String, Object>> campaigns(List<AdCampaignRow> rows) {
        return rows.stream().map(this::campaign).toList();
    }

    /** C端投放视角：仅门店展示信息 + 广告标识。 */
    public Map<String, Object> serving(AdCampaignRow c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("campaignId", c.getId());
        m.put("shopId", c.getShopId());
        m.put("shopName", c.getShopName() == null ? "" : c.getShopName());
        m.put("coverUrl", c.getCoverUrl() == null ? "" : c.getCoverUrl());
        m.put("score", c.getScore());
        m.put("ad", true);
        return m;
    }

    private String slotText(Integer slotType) {
        return slotType != null && slotType == 2 ? "首页/列表" : "搜索结果";
    }

    private String statusText(Integer status) {
        if (status == null) return "投放中";
        return switch (status) {
            case 0 -> "已下线";
            case 2 -> "已暂停";
            default -> "投放中";
        };
    }

    private String auditText(Integer auditStatus) {
        if (auditStatus == null) return "待审核";
        return switch (auditStatus) {
            case 2 -> "已通过";
            case 3 -> "已驳回";
            default -> "待审核";
        };
    }
}
