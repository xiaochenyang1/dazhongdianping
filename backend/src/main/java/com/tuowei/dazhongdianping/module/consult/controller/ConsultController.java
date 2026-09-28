package com.tuowei.dazhongdianping.module.consult.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.consult.model.request.ConsultMessageRequest;
import com.tuowei.dazhongdianping.module.consult.model.request.ConsultStartRequest;
import com.tuowei.dazhongdianping.module.consult.service.ConsultService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
    public ApiResponse<List<Map<String, Object>>> sessions() {
        return ApiResponse.success(service.mySessions());
    }

    @GetMapping("/sessions/{id}/messages")
    public ApiResponse<Map<String, Object>> messages(@PathVariable Long id) {
        return ApiResponse.success(service.messages(id));
    }

    @PostMapping("/sessions/{id}/messages")
    public ApiResponse<Map<String, Object>> send(
            @PathVariable Long id, @Valid @RequestBody ConsultMessageRequest request) {
        return ApiResponse.success(service.send(id, request));
    }
}
