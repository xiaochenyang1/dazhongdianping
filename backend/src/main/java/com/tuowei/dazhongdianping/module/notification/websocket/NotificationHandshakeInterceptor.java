package com.tuowei.dazhongdianping.module.notification.websocket;

import java.net.URI;
import java.util.Map;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class NotificationHandshakeInterceptor implements HandshakeInterceptor {
    private final WebSocketTicketService tickets;
    public NotificationHandshakeInterceptor(WebSocketTicketService tickets) { this.tickets = tickets; }
    @Override public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler wsHandler, Map<String, Object> attributes) {
        URI uri = request.getURI(); String value = UriComponentsBuilder.fromUri(uri).build().getQueryParams().getFirst("ticket");
        WebSocketTicketService.Ticket ticket = tickets.consume(value); if (ticket == null) return false;
        attributes.put("userId", ticket.userId()); attributes.put("region", ticket.region()); return true;
    }
    @Override public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response, WebSocketHandler wsHandler, Exception exception) { }
}
