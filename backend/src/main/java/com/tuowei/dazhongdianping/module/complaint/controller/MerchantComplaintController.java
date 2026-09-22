package com.tuowei.dazhongdianping.module.complaint.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.complaint.model.request.ComplaintReplyRequest;
import com.tuowei.dazhongdianping.module.complaint.service.MerchantComplaintService;
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
@RequestMapping("/api/b/v1/complaints")
public class MerchantComplaintController {

    private final MerchantComplaintService service;

    public MerchantComplaintController(MerchantComplaintService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> complaints(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.complaints(status, page, pageSize));
    }

    @GetMapping("/{id}")
    public ApiResponse<Map<String, Object>> detail(@PathVariable Long id) {
        return ApiResponse.success(service.detail(id));
    }

    @PostMapping("/{id}/reply")
    public ApiResponse<Map<String, Object>> reply(
            @PathVariable Long id, @Valid @RequestBody ComplaintReplyRequest request) {
        return ApiResponse.success("申辩已提交", "merchant.complaint_reply_saved",
                service.reply(id, request));
    }
}
