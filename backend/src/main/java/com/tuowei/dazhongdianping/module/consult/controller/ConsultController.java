package com.tuowei.dazhongdianping.module.consult.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.consult.model.request.ConsultMessageRequest;
import com.tuowei.dazhongdianping.module.consult.model.request.ConsultStartRequest;
import com.tuowei.dazhongdianping.module.consult.service.ConsultService;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import org.springframework.format.annotation.DateTimeFormat;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestParam;

@RestController
@RequestMapping("/api/c/v1/consult")
public class ConsultController {

    private final ConsultService service;

    public ConsultController(ConsultService service) {
        this.service = service;
    }

    @PostMapping("/sessions")
    public ApiResponse<Map<String, Object>> start(@Valid @RequestBody ConsultStartRequest request) {
        return ApiResponse.success(service.startSession(request.shopId()));
    }

    @GetMapping("/sessions")
    public ApiResponse<Map<String, Object>> sessions(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime beforeUpdatedAt,
            @RequestParam(required = false) Long beforeId,
            @RequestParam(required = false) Integer pageSize,
            @RequestParam(defaultValue = "false") boolean unreadOnly) {
        return ApiResponse.success(service.mySessions(beforeUpdatedAt, beforeId, pageSize, unreadOnly));
    }

    @GetMapping("/sessions/{id}/messages")
    public ApiResponse<Map<String, Object>> messages(@PathVariable Long id,
            @RequestParam(required = false) Long beforeId,
            @RequestParam(required = false) Long afterId,
            @RequestParam(required = false) Integer pageSize) {
        return ApiResponse.success(service.messages(id, beforeId, afterId, pageSize));
    }

    @PostMapping("/sessions/{id}/messages")
    public ApiResponse<Map<String, Object>> send(
            @PathVariable Long id, @Valid @RequestBody ConsultMessageRequest request) {
        return ApiResponse.success(service.send(id, request));
    }
}
