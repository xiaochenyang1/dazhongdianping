package com.tuowei.dazhongdianping.config;

import com.tuowei.dazhongdianping.module.notification.websocket.NotificationHandshakeInterceptor;
import com.tuowei.dazhongdianping.module.notification.websocket.NotificationWebSocketHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class NotificationWebSocketConfig implements WebSocketConfigurer {
    private final NotificationWebSocketHandler handler;
    private final NotificationHandshakeInterceptor interceptor;
    private final CorsProperties corsProperties;

    public NotificationWebSocketConfig(NotificationWebSocketHandler handler,
                                       NotificationHandshakeInterceptor interceptor,
                                       CorsProperties corsProperties) {
        this.handler = handler;
        this.interceptor = interceptor;
        this.corsProperties = corsProperties;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/notifications")
                .addInterceptors(interceptor)
                .setAllowedOriginPatterns(corsProperties.getAllowedOriginPatterns().toArray(String[]::new));
    }
}
