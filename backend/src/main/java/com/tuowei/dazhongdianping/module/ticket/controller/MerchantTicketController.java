package com.tuowei.dazhongdianping.module.ticket.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.ticket.model.request.MerchantTicketCreateRequest;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketMessageRequest;
import com.tuowei.dazhongdianping.module.ticket.service.MerchantTicketService;
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
@RequestMapping("/api/b/v1/tickets")
public class MerchantTicketController {

    private final MerchantTicketService service;

    public MerchantTicketController(MerchantTicketService service) {
        this.service = service;
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> create(@Valid @RequestBody MerchantTicketCreateRequest request) {
        return ApiResponse.success("工单已提交", "merchant.ticket_created", service.create(request));
    }

    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> tickets(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.tickets(page, pageSize));
    }

    @PostMapping("/{id}/messages")
    public ApiResponse<Map<String, Object>> reply(
            @PathVariable Long id, @Valid @RequestBody TicketMessageRequest request) {
        return ApiResponse.success("回复已提交", "merchant.ticket_message_created", service.reply(id, request));
    }
}
