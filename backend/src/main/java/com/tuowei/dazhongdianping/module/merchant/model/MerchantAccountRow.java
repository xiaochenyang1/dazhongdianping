package com.tuowei.dazhongdianping.module.merchant.model;

import lombok.Data;

@Data
public class MerchantAccountRow {

    private Long id;
    private String account;
    private String companyName;
    private String region;
    private Integer auditStatus;
    private Integer status;
}
