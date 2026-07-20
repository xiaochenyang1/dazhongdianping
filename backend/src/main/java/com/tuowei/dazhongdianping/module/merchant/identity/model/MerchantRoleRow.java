package com.tuowei.dazhongdianping.module.merchant.identity.model;

import lombok.Data;

@Data
public class MerchantRoleRow {

    private Long id;
    private String code;
    private String name;
    private String permissions;
}
