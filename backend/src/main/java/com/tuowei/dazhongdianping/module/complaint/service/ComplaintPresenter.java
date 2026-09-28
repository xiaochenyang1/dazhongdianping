package com.tuowei.dazhongdianping.module.complaint.service;

import com.tuowei.dazhongdianping.module.complaint.mapper.ComplaintMapper;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintLogRow;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintTicketRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

/** 投诉工单/日志到响应体的统一映射（C/商家/平台三端共用）。 */
@Component
public class ComplaintPresenter {

    private final ComplaintMapper mapper;

    public ComplaintPresenter(ComplaintMapper mapper) {
        this.mapper = mapper;
    }

    public Map<String, Object> ticket(ComplaintTicketRow t, boolean includeLogs) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.getId());
        m.put("ticketNo", t.getTicketNo());
        m.put("userId", t.getUserId());
        m.put("userNickname", t.getUserNickname() == null ? "" : t.getUserNickname());
        m.put("shopId", t.getShopId());
        m.put("shopName", t.getShopName() == null ? "" : t.getShopName());
        m.put("orderId", t.getOrderId());
        m.put("type", t.getType());
        m.put("typeText", typeText(t.getType()));
        m.put("title", t.getTitle());
        m.put("content", t.getContent());
        m.put("status", t.getStatus());
        m.put("statusText", statusText(t.getStatus()));
        m.put("merchantReply", t.getMerchantReply() == null ? "" : t.getMerchantReply());
        m.put("merchantRepliedAt", t.getMerchantRepliedAt());
        m.put("resolution", t.getResolution() == null ? "" : t.getResolution());
        m.put("resolvedAt", t.getResolvedAt());
        m.put("createdAt", t.getCreatedAt());
        m.put("updatedAt", t.getUpdatedAt());
        if (includeLogs) {
            m.put("logs", mapper.selectLogs(t.getId()).stream().map(this::log).toList());
        }
        return m;
    }

    private Map<String, Object> log(ComplaintLogRow l) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", l.getId());
        m.put("actorType", l.getActorType());
        m.put("actorTypeText", actorText(l.getActorType()));
        m.put("action", l.getAction());
        m.put("actionText", actionText(l.getAction()));
        m.put("remark", l.getRemark() == null ? "" : l.getRemark());
        m.put("createdAt", l.getCreatedAt());
        return m;
    }

    public List<Map<String, Object>> tickets(List<ComplaintTicketRow> rows) {
        return rows.stream().map(t -> ticket(t, false)).toList();
    }

    private String typeText(Integer type) {
        if (type == null) return "其他";
        return switch (type) {
            case 1 -> "商品/服务质量";
            case 2 -> "虚假宣传";
            case 3 -> "退款纠纷";
            case 4 -> "服务态度";
            default -> "其他";
        };
    }

    private String statusText(Integer status) {
        if (status == null) return "待受理";
        return switch (status) {
            case 2 -> "处理中";
            case 3 -> "已解决";
            case 4 -> "已驳回";
            default -> "待受理";
        };
    }

    private String actorText(Integer actorType) {
        if (actorType == null) return "";
        return switch (actorType) {
            case 2 -> "商家";
            case 3 -> "平台";
            default -> "用户";
        };
    }

    private String actionText(Integer action) {
        if (action == null) return "";
        return switch (action) {
            case 2 -> "商家申辩";
            case 3 -> "平台受理";
            case 4 -> "已解决";
            case 5 -> "已驳回";
            default -> "创建投诉";
        };
    }
}
