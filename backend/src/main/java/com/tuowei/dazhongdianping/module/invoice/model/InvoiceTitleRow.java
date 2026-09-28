package com.tuowei.dazhongdianping.module.invoice.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class InvoiceTitleRow {

    private Long id;
    private Long userId;
    private String region;
    private Integer titleType;
    private String name;
    private String taxNo;
    private String email;
    private Boolean isDefault;
    private LocalDateTime createdAt;
}
