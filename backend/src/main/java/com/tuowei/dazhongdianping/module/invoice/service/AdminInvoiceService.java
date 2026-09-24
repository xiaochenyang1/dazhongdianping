package com.tuowei.dazhongdianping.module.invoice.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.invoice.mapper.InvoiceMapper;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceRequestRow;
import com.tuowei.dazhongdianping.module.invoice.model.TaxRateRow;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceIssueRequest;
import com.tuowei.dazhongdianping.module.invoice.model.request.InvoiceRejectRequest;
import com.tuowei.dazhongdianping.module.invoice.model.request.TaxRateSaveRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 平台发票审核与税率维护。状态：1 待开票 2 已开票 3 已驳回。 */
@Service
public class AdminInvoiceService {

    private final InvoiceMapper mapper;

    public AdminInvoiceService(InvoiceMapper mapper) {
        this.mapper = mapper;
    }

    public PageResult<Map<String, Object>> invoices(Integer status, Integer page, Integer pageSize) {
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countAdminRequests(region, status);
        List<Map<String, Object>> list = mapper.selectAdminRequests(region, status, s, (p - 1) * s)
                .stream().map(this::requestMap).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> issue(Long id, InvoiceIssueRequest request) {
        String region = region();
        if (mapper.selectRequest(id, region) == null) {
            throw new NotFoundException("开票申请不存在");
        }
        if (mapper.issue(id, region, request.invoiceNo().trim()) == 0) {
            throw new ConflictException("开票申请当前状态不可开具");
        }
        return requestMap(mapper.selectRequest(id, region));
    }

    @Transactional
    public Map<String, Object> reject(Long id, InvoiceRejectRequest request) {
        String region = region();
        if (mapper.selectRequest(id, region) == null) {
            throw new NotFoundException("开票申请不存在");
        }
        if (mapper.reject(id, region, request.reason().trim()) == 0) {
            throw new ConflictException("开票申请当前状态不可驳回");
        }
        return requestMap(mapper.selectRequest(id, region));
    }

    public List<Map<String, Object>> taxRates() {
        return mapper.selectTaxRates(region()).stream().map(this::taxMap).toList();
    }

    @Transactional
    public Map<String, Object> updateTaxRate(Long id, TaxRateSaveRequest request) {
        String region = region();
        if (mapper.selectTaxRate(id, region) == null) {
            throw new NotFoundException("税率不存在");
        }
        TaxRateRow row = new TaxRateRow();
        row.setId(id);
        row.setRegion(region);
        row.setName(request.name().trim());
        row.setRateBp(request.rateBp());
        row.setStatus(request.status());
        mapper.updateTaxRate(row);
        return taxMap(mapper.selectTaxRate(id, region));
    }

    private Map<String, Object> requestMap(InvoiceRequestRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("userId", row.getUserId());
        body.put("orderId", row.getOrderId());
        body.put("titleId", row.getTitleId());
        body.put("amount", row.getAmount());
        body.put("taxAmount", row.getTaxAmount());
        body.put("currency", row.getCurrency());
        body.put("status", row.getStatus());
        body.put("statusText", switch (row.getStatus() == null ? 1 : row.getStatus()) {
            case 2 -> "已开票";
            case 3 -> "已驳回";
            default -> "待开票";
        });
        body.put("invoiceNo", row.getInvoiceNo() == null ? "" : row.getInvoiceNo());
        body.put("rejectReason", row.getRejectReason() == null ? "" : row.getRejectReason());
        body.put("createdAt", row.getCreatedAt());
        return body;
    }

    private Map<String, Object> taxMap(TaxRateRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("region", row.getRegion());
        body.put("name", row.getName());
        body.put("rateBp", row.getRateBp());
        body.put("status", row.getStatus());
        return body;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
