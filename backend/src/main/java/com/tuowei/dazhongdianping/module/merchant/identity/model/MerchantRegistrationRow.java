package com.tuowei.dazhongdianping.module.merchant.identity.model;

import lombok.Data;

@Data
public class MerchantRegistrationRow {

    private Long id;
    private String account;
    private String companyName;
    private String contactName;
    private String contactPhone;
    private String region;
    private Integer auditStatus;
    private Integer status;
}
