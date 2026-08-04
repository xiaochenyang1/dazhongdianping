package com.tuowei.dazhongdianping.module.admin.merchant.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminMerchantOperatorRow {

    private Long id;
    private Long merchantId;
    private String account;
    private String name;
    private String phone;
    private String email;
    private Integer shopScopeType;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
