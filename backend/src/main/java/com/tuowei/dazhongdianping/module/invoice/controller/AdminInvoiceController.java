package com.tuowei.dazhongdianping.module.invoice.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceIssueRequest;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceRejectRequest;
import com.tuowei.dazhongdianping.module.invoice.model.request.TaxRateSaveRequest;
import com.tuowei.dazhongdianping.module.invoice.service.AdminInvoiceService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1")
public class AdminInvoiceController {

    private final AdminInvoiceService service;

    public AdminInvoiceController(AdminInvoiceService service) {
        this.service = service;
    }

    @GetMapping("/invoices")
    @AdminPermission("finance:invoice:read")
    public ApiResponse<PageResult<Map<String, Object>>> invoices(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "12") Integer pageSize) {
        return ApiResponse.success(service.invoices(status, page, pageSize));
    }

    @PostMapping("/invoices/{id}/issue")
    @AdminPermission("finance:invoice:write")
    public ApiResponse<Map<String, Object>> issue(
            @PathVariable Long id, @Valid @RequestBody InvoiceIssueRequest request) {
        return ApiResponse.success("已开票", "invoice.issued", service.issue(id, request));
    }

    @PostMapping("/invoices/{id}/reject")
    @AdminPermission("finance:invoice:write")
    public ApiResponse<Map<String, Object>> reject(
            @PathVariable Long id, @Valid @RequestBody InvoiceRejectRequest request) {
        return ApiResponse.success("已驳回", "invoice.rejected", service.reject(id, request));
    }

    @GetMapping("/tax-rates")
    @AdminPermission("finance:invoice:read")
    public ApiResponse<List<Map<String, Object>>> taxRates() {
        return ApiResponse.success(service.taxRates());
    }

    @PutMapping("/tax-rates/{id}")
    @AdminPermission("finance:invoice:write")
    public ApiResponse<Map<String, Object>> updateTaxRate(
            @PathVariable Long id, @Valid @RequestBody TaxRateSaveRequest request) {
        return ApiResponse.success("税率已更新", "invoice.tax_rate_saved", service.updateTaxRate(id, request));
    }
}
