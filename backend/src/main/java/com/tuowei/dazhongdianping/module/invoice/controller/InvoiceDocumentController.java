package com.tuowei.dazhongdianping.module.invoice.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceReceiptRequest;
import com.tuowei.dazhongdianping.module.invoice.service.InvoiceDocumentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class InvoiceDocumentController {
    private final InvoiceDocumentService service;
    public InvoiceDocumentController(InvoiceDocumentService service) { this.service = service; }

    @PostMapping(value = "/api/admin/v1/invoices/{id}/document", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @AdminPermission("finance:invoice:write")
    public ApiResponse<Map<String, Object>> upload(@PathVariable Long id, @RequestParam String invoiceNo,
            @RequestParam MultipartFile file, HttpServletRequest request) {
        return ApiResponse.success(service.upload(id, invoiceNo, file, request.getRemoteAddr()));
    }

    @GetMapping("/api/admin/v1/invoices/{id}/document")
    @AdminPermission("finance:invoice:read")
    public ResponseEntity<byte[]> adminDownload(@PathVariable Long id, HttpServletRequest request) {
        return service.download(id, false, request.getRemoteAddr());
    }

    @GetMapping("/api/c/v1/invoices/{id}/document")
    public ResponseEntity<byte[]> download(@PathVariable Long id) { return service.download(id, true, ""); }

    @PostMapping("/api/c/v1/invoices/{id}/receipt")
    public ApiResponse<Map<String, Object>> receipt(@PathVariable Long id, @Valid @RequestBody InvoiceReceiptRequest request) {
        return ApiResponse.success(service.confirmReceipt(id, request.sha256()));
    }
}
