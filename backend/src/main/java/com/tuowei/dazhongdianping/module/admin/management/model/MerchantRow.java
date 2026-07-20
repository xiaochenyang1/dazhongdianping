package com.tuowei.dazhongdianping.module.admin.management.model;

import lombok.Data;

@Data
public class MerchantRow {
    private Long id;
    private String account;
    private String companyName;
    private String contactName;
    private String contactPhone;
    private String region;
    private Integer auditStatus;
    private Integer status;
}
