package com.tuowei.dazhongdianping.module.merchant.identity.model;

import lombok.Data;

@Data
public class MerchantOperatorRow {

    private Long id;
    private Long merchantId;
    private String account;
    private String passwordHash;
    private String name;
    private String phone;
    private String email;
    private Integer operatorType;
    private Integer shopScopeType;
    private Integer operatorStatus;
    private Integer merchantStatus;
    private Integer auditStatus;
    private String region;
}
