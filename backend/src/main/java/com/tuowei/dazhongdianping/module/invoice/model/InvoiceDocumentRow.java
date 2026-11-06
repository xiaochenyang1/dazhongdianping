package com.tuowei.dazhongdianping.module.invoice.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class InvoiceDocumentRow {
    private Long invoiceId;
    @JsonIgnore private byte[] content;
    private String sha256;
    private Integer sizeBytes;
    @JsonIgnore private Long uploadedBy;
    private LocalDateTime uploadedAt;
    private LocalDateTime receivedAt;

    public String getFileName() { return "invoice-" + invoiceId + ".pdf"; }
}
