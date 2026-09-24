package com.tuowei.dazhongdianping.module.ticket.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketMessageRequest;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketStatusRequest;
import com.tuowei.dazhongdianping.module.ticket.service.AdminTicketService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/tickets")
public class AdminTicketController {

    private final AdminTicketService service;

    public AdminTicketController(AdminTicketService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("support:ticket:read")
    public ApiResponse<PageResult<Map<String, Object>>> tickets(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.tickets(status, page, pageSize));
    }

    @GetMapping("/{id}")
    @AdminPermission("support:ticket:read")
    public ApiResponse<Map<String, Object>> detail(@PathVariable Long id) {
        return ApiResponse.success(service.detail(id));
    }

    @PostMapping("/{id}/reply")
    @AdminPermission("support:ticket:write")
    public ApiResponse<Map<String, Object>> reply(
            @PathVariable Long id, @Valid @RequestBody TicketMessageRequest request) {
        return ApiResponse.success("回复已提交", "admin.ticket_replied", service.reply(id, request));
    }

    @PostMapping("/{id}/status")
    @AdminPermission("support:ticket:write")
    public ApiResponse<Map<String, Object>> updateStatus(
            @PathVariable Long id, @Valid @RequestBody TicketStatusRequest request) {
        return ApiResponse.success("工单状态已更新", "admin.ticket_updated", service.updateStatus(id, request));
    }
}
