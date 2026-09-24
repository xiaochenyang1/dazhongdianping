package com.tuowei.dazhongdianping.module.ticket.service;

import com.tuowei.dazhongdianping.module.ticket.mapper.TicketMapper;
import com.tuowei.dazhongdianping.module.ticket.model.SupportTicketRow;
import com.tuowei.dazhongdianping.module.ticket.model.TicketMessageRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

/** 客服工单到响应体的统一映射（C / 商家 / 平台共用）。 */
@Component
public class TicketPresenter {

    private final TicketMapper mapper;

    public TicketPresenter(TicketMapper mapper) {
        this.mapper = mapper;
    }

    public Map<String, Object> ticket(SupportTicketRow t, boolean includeMessages) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.getId());
        m.put("requesterType", t.getRequesterType());
        m.put("requesterId", t.getRequesterId());
        m.put("shopId", t.getShopId());
        m.put("shopName", t.getShopName() == null ? "" : t.getShopName());
        m.put("subject", t.getSubject());
        m.put("content", t.getContent());
        m.put("status", t.getStatus());
        m.put("statusText", statusText(t.getStatus()));
        m.put("createdAt", t.getCreatedAt());
        m.put("updatedAt", t.getUpdatedAt());
        if (includeMessages) {
            m.put("messages", mapper.selectMessages(t.getId()).stream().map(this::message).toList());
        }
        return m;
    }

    public List<Map<String, Object>> tickets(List<SupportTicketRow> rows) {
        return rows.stream().map(t -> ticket(t, false)).toList();
    }

    private Map<String, Object> message(TicketMessageRow row) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", row.getId());
        m.put("senderType", row.getSenderType());
        m.put("senderId", row.getSenderId());
        m.put("content", row.getContent());
        m.put("createdAt", row.getCreatedAt());
        return m;
    }

    private String statusText(Integer status) {
        if (status == null) {
            return "待处理";
        }
        return switch (status) {
            case 2 -> "处理中";
            case 3 -> "已解决";
            case 4 -> "已关闭";
            default -> "待处理";
        };
    }
}
