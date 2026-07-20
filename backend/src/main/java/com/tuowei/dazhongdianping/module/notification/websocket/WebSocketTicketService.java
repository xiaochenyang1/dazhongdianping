package com.tuowei.dazhongdianping.module.notification.websocket;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Service;

@Service
public class WebSocketTicketService {
    private static final long EXPIRES_SECONDS = 60;
    private final Map<String, Ticket> tickets = new ConcurrentHashMap<>();

    public Map<String, Object> issue(Long userId, String region) {
        String value = UUID.randomUUID().toString().replace("-", "");
        tickets.put(value, new Ticket(userId, region, Instant.now().plusSeconds(EXPIRES_SECONDS)));
        return Map.of("ticket", value, "expiresInSeconds", EXPIRES_SECONDS);
    }

    public Ticket consume(String value) {
        Ticket ticket = value == null ? null : tickets.remove(value);
        return ticket != null && ticket.expiresAt().isAfter(Instant.now()) ? ticket : null;
    }

    public record Ticket(Long userId, String region, Instant expiresAt) {}
}
