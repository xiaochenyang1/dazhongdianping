package com.tuowei.dazhongdianping.module.consult.service;

import com.tuowei.dazhongdianping.module.consult.model.ConsultMessageRow;
import com.tuowei.dazhongdianping.module.consult.model.ConsultSessionRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

/** 咨询会话/消息到响应体的统一映射。viewerType：1=用户端 2=商家端（决定 unread 取哪一侧）。 */
@Component
public class ConsultPresenter {

    public Map<String, Object> session(ConsultSessionRow s, int viewerType) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", s.getId());
        m.put("shopId", s.getShopId());
        m.put("shopName", s.getShopName() == null ? "" : s.getShopName());
        m.put("userId", s.getUserId());
        m.put("userNickname", s.getUserNickname() == null ? "" : s.getUserNickname());
        m.put("lastMessage", s.getLastMessage() == null ? "" : s.getLastMessage());
        m.put("lastMessageAt", s.getLastMessageAt());
        int unread = viewerType == 2
                ? (s.getMerchantUnread() == null ? 0 : s.getMerchantUnread())
                : (s.getUserUnread() == null ? 0 : s.getUserUnread());
        m.put("unread", unread);
        m.put("createdAt", s.getCreatedAt());
        m.put("updatedAt", s.getUpdatedAt());
        return m;
    }

    public List<Map<String, Object>> sessions(List<ConsultSessionRow> rows, int viewerType) {
        return rows.stream().map(s -> session(s, viewerType)).toList();
    }

    public Map<String, Object> message(ConsultMessageRow r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("sessionId", r.getSessionId());
        m.put("senderType", r.getSenderType());
        m.put("senderId", r.getSenderId());
        m.put("content", r.getContent());
        m.put("createdAt", r.getCreatedAt());
        return m;
    }

    public List<Map<String, Object>> messages(List<ConsultMessageRow> rows) {
        return rows.stream().map(this::message).toList();
    }
}
