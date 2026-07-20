package com.tuowei.dazhongdianping.module.notification.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

@Component
public class NotificationSessionRegistry {
    private final ObjectMapper objectMapper;
    private final Map<String, Set<WebSocketSession>> sessions = new ConcurrentHashMap<>();

    public NotificationSessionRegistry(ObjectMapper objectMapper) { this.objectMapper = objectMapper; }
    public void add(Long userId, String region, WebSocketSession session) { sessions.computeIfAbsent(key(userId, region), ignored -> ConcurrentHashMap.newKeySet()).add(session); }
    public void remove(Long userId, String region, WebSocketSession session) { Set<WebSocketSession> current = sessions.get(key(userId, region)); if (current != null) current.remove(session); }
    public void send(Long userId, String region, Object payload) {
        Set<WebSocketSession> current = sessions.get(key(userId, region)); if (current == null) return;
        try { TextMessage message = new TextMessage(objectMapper.writeValueAsString(payload)); for (WebSocketSession session : current) if (session.isOpen()) session.sendMessage(message); }
        catch (IOException ignored) { }
    }
    public void sendAllRegions(Long userId, Object payload) {
        send(userId, "CN", payload);
        send(userId, "EU", payload);
    }
    private String key(Long userId, String region) { return userId + ":" + region; }
}
