package com.tuowei.dazhongdianping.module.merchant.trade.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantDealSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantDealStatusRequest;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantRefundAuditRequest;
import com.tuowei.dazhongdianping.module.merchant.trade.service.MerchantTradeService;
import jakarta.validation.Valid;
import java.time.LocalDate;
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
@RequestMapping("/api/b/v1")
public class MerchantTradeController {

    private final MerchantTradeService service;

    public MerchantTradeController(MerchantTradeService service) {
        this.service = service;
    }

    @GetMapping("/deals")
    public ApiResponse<PageResult<Map<String, Object>>> deals(
            @RequestParam(required = false) Long shopId,
            @RequestParam(required = false) Integer auditStatus,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer pageSize
    ) {
        return ApiResponse.success(service.deals(shopId, auditStatus, status, page, pageSize));
    }

    @GetMapping("/deals/{id}")
    public ApiResponse<Map<String, Object>> deal(@PathVariable Long id) {
        return ApiResponse.success(service.deal(id));
    }

    @PostMapping("/deals")
    public ApiResponse<Map<String, Object>> createDeal(@Valid @RequestBody MerchantDealSaveRequest request) {
        return ApiResponse.success("团购已提交审核", "merchant.deal_submitted", service.createDeal(request));
    }

    @PutMapping("/deals/{id}")
    public ApiResponse<Map<String, Object>> updateDeal(
            @PathVariable Long id,
            @Valid @RequestBody MerchantDealSaveRequest request
    ) {
        return ApiResponse.success("团购已重新提交审核", "merchant.deal_resubmitted", service.updateDeal(id, request));
    }

    @PutMapping("/deals/{id}/status")
    public ApiResponse<Map<String, Object>> changeDealStatus(
            @PathVariable Long id,
            @Valid @RequestBody MerchantDealStatusRequest request
    ) {
        return ApiResponse.success(service.changeDealStatus(id, request.status()));
    }

    @GetMapping("/orders")
    public ApiResponse<PageResult<Map<String, Object>>> orders(
            @RequestParam(required = false) Long shopId,
            @RequestParam(required = false) Integer payStatus,
            @RequestParam(required = false) Integer refundStatus,
            @RequestParam(required = false) String orderNo,
            @RequestParam(required = false) LocalDate dateFrom,
            @RequestParam(required = false) LocalDate dateTo,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer pageSize
    ) {
        return ApiResponse.success(service.orders(
                shopId, payStatus, refundStatus, orderNo, dateFrom, dateTo, page, pageSize
        ));
    }

    @PostMapping("/orders/{id}/refund-audit")
    public ApiResponse<Map<String, Object>> auditRefund(
            @PathVariable Long id,
            @Valid @RequestBody MerchantRefundAuditRequest request
    ) {
        return ApiResponse.success(service.auditRefund(id, request));
    }
}
