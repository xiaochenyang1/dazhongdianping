package com.tuowei.dazhongdianping.module.invoice.service;

import com.tuowei.dazhongdianping.module.invoice.model.InvoiceRequestRow;
import java.util.LinkedHashMap;
import java.util.Map;

final class InvoiceProjection {
    private InvoiceProjection() { }
    static Map<String, Object> request(InvoiceRequestRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("orderId", row.getOrderId());
        body.put("orderNo", row.getOrderNo());
        body.put("titleId", row.getTitleId());
        body.put("titleName", row.getTitleName());
        body.put("titleType", row.getTitleType());
        body.put("taxNo", row.getTaxNo());
        body.put("email", row.getEmail());
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
        boolean available = row.getDocumentSha256() != null;
        body.put("documentAvailable", available);
        body.put("documentFileName", available ? "invoice-" + row.getId() + ".pdf" : "");
        body.put("documentSha256", row.getDocumentSha256());
        body.put("documentSize", row.getDocumentSize());
        body.put("documentUploadedAt", row.getDocumentUploadedAt());
        body.put("receivedAt", row.getReceivedAt());
        return body;
    }
}
