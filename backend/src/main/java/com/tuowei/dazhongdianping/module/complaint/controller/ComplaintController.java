package com.tuowei.dazhongdianping.module.complaint.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.complaint.model.request.ComplaintCreateRequest;
import com.tuowei.dazhongdianping.module.complaint.service.ComplaintService;
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
@RequestMapping("/api/c/v1/complaints")
public class ComplaintController {

    private final ComplaintService service;

    public ComplaintController(ComplaintService service) {
        this.service = service;
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> create(@Valid @RequestBody ComplaintCreateRequest request) {
        return ApiResponse.success("投诉已提交", "complaint.created", service.create(request));
    }

    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> myComplaints(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.myComplaints(status, page, pageSize));
    }

    @GetMapping("/{id}")
    public ApiResponse<Map<String, Object>> detail(@PathVariable Long id) {
        return ApiResponse.success(service.detail(id));
    }
}
