package com.tuowei.dazhongdianping.module.notification.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.notification.websocket.WebSocketTicketService;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1")
public class NotificationController {
    private final NotificationService notifications;
    private final WebSocketTicketService tickets;

    public NotificationController(NotificationService notifications, WebSocketTicketService tickets) {
        this.notifications = notifications;
        this.tickets = tickets;
    }

    @GetMapping("/notifications")
    public ApiResponse<PageResult<Map<String, Object>>> list(@RequestParam(required = false) Integer page,
                                                              @RequestParam(required = false) Integer pageSize) {
        return ApiResponse.success(notifications.list(userId(), region(), page, pageSize));
    }

    @GetMapping("/notifications/unread-count")
    public ApiResponse<Map<String, Object>> unreadCount() {
        return ApiResponse.success(notifications.unreadCount(userId(), region()));
    }

    @PostMapping("/notifications/{id}/ack")
    public ApiResponse<Map<String, Object>> ack(@PathVariable Long id) {
        return ApiResponse.success(notifications.ack(id, userId(), region()));
    }

    @PostMapping("/ws/ticket")
    public ApiResponse<Map<String, Object>> ticket() {
        return ApiResponse.success(tickets.issue(userId(), region()));
    }

    private Long userId() { return UserSessionContext.get().userId(); }
    private String region() { return RegionContext.getRegion().name(); }
}
