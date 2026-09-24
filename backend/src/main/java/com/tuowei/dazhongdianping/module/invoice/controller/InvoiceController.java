package com.tuowei.dazhongdianping.module.invoice.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceApplyRequest;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceTitleSaveRequest;
import com.tuowei.dazhongdianping.module.invoice.service.InvoiceService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/invoices")
public class InvoiceController {

    private final InvoiceService service;

    public InvoiceController(InvoiceService service) {
        this.service = service;
    }

    @GetMapping("/titles")
    public ApiResponse<List<Map<String, Object>>> titles() {
        return ApiResponse.success(service.titles());
    }

    @PostMapping("/titles")
    public ApiResponse<Map<String, Object>> createTitle(@Valid @RequestBody InvoiceTitleSaveRequest request) {
        return ApiResponse.success("抬头已保存", "invoice.title_saved", service.createTitle(request));
    }

    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> invoices(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.invoices(page, pageSize));
    }

    @PostMapping
    public ApiResponse<Map<String, Object>> apply(@Valid @RequestBody InvoiceApplyRequest request) {
        return ApiResponse.success("开票申请已提交", "invoice.requested", service.apply(request));
    }
}
