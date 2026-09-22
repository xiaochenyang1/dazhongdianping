package com.tuowei.dazhongdianping.module.consult.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.consult.model.request.ConsultMessageRequest;
import com.tuowei.dazhongdianping.module.consult.service.MerchantConsultService;
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
@RequestMapping("/api/b/v1/consult")
public class MerchantConsultController {

    private final MerchantConsultService service;

    public MerchantConsultController(MerchantConsultService service) {
        this.service = service;
    }

    @GetMapping("/sessions")
    public ApiResponse<List<Map<String, Object>>> sessions() {
        return ApiResponse.success(service.sessions());
    }

    @GetMapping("/sessions/{id}/messages")
    public ApiResponse<Map<String, Object>> messages(@PathVariable Long id) {
        return ApiResponse.success(service.messages(id));
    }

    @PostMapping("/sessions/{id}/messages")
    public ApiResponse<Map<String, Object>> send(
            @PathVariable Long id, @Valid @RequestBody ConsultMessageRequest request) {
        return ApiResponse.success("已回复", "merchant.consult_replied", service.send(id, request));
    }
}
