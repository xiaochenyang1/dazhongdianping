package com.tuowei.dazhongdianping.config;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.module.notification.websocket.NotificationHandshakeInterceptor;
import com.tuowei.dazhongdianping.module.notification.websocket.NotificationWebSocketHandler;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistration;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

class NotificationWebSocketConfigTest {

    @Test
    void shouldReuseHttpCorsOriginsForWebSocketHandshakes() {
        NotificationWebSocketHandler handler = mock(NotificationWebSocketHandler.class);
        NotificationHandshakeInterceptor interceptor = mock(NotificationHandshakeInterceptor.class);
        CorsProperties cors = new CorsProperties();
        cors.setAllowedOriginPatterns(List.of("https://eu.example.test", "https://admin.example.test"));
        WebSocketHandlerRegistry registry = mock(WebSocketHandlerRegistry.class);
        WebSocketHandlerRegistration registration = mock(WebSocketHandlerRegistration.class);
        when(registry.addHandler(handler, "/ws/notifications")).thenReturn(registration);
        when(registration.addInterceptors(interceptor)).thenReturn(registration);

        new NotificationWebSocketConfig(handler, interceptor, cors).registerWebSocketHandlers(registry);

        verify(registration).setAllowedOriginPatterns("https://eu.example.test", "https://admin.example.test");
    }
}
