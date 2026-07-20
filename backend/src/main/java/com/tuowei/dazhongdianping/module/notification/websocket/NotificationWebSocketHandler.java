package com.tuowei.dazhongdianping.module.notification.websocket;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import java.util.Map;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class NotificationWebSocketHandler extends TextWebSocketHandler {
    private final ObjectMapper objectMapper; private final NotificationSessionRegistry registry; private final NotificationService notifications;
    public NotificationWebSocketHandler(ObjectMapper objectMapper, NotificationSessionRegistry registry, NotificationService notifications) { this.objectMapper = objectMapper; this.registry = registry; this.notifications = notifications; }
    @Override public void afterConnectionEstablished(WebSocketSession session) throws Exception { registry.add(userId(session), region(session), session); session.sendMessage(json(Map.of("type", "welcome"))); }
    @Override protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        JsonNode payload = objectMapper.readTree(message.getPayload()); String type = payload.path("type").asText();
        if ("ping".equals(type)) { session.sendMessage(json(Map.of("type", "pong"))); return; }
        if ("ack".equals(type) && payload.path("notificationId").canConvertToLong()) { long id = payload.path("notificationId").asLong(); notifications.ack(id, userId(session), region(session)); session.sendMessage(json(Map.of("type", "notification.ack", "notificationId", id))); }
    }
    @Override public void afterConnectionClosed(WebSocketSession session, CloseStatus status) { registry.remove(userId(session), region(session), session); }
    private TextMessage json(Object value) throws Exception { return new TextMessage(objectMapper.writeValueAsString(value)); }
    private Long userId(WebSocketSession session) { return ((Number) session.getAttributes().get("userId")).longValue(); }
    private String region(WebSocketSession session) { return String.valueOf(session.getAttributes().get("region")); }
}
