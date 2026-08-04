package com.tuowei.dazhongdianping.module.admin.merchant.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class AdminMerchantQuery {

    private String keyword;

    @Min(value = 1, message = "merchantId 最小为 1")
    private Long merchantId;

    @Min(value = 0, message = "auditStatus 最小为 0")
    @Max(value = 2, message = "auditStatus 最大为 2")
    private Integer auditStatus;

    @Min(value = 1, message = "status 最小为 1")
    @Max(value = 2, message = "status 最大为 2")
    private Integer status;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 50, message = "pageSize 最大为 50")
    private Integer pageSize = 20;

    public int getOffset() {
        return (page - 1) * pageSize;
    }

    public void normalize() {
        keyword = StringUtils.hasText(keyword) ? keyword.trim() : null;
        if (page == null || page < 1) {
            page = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 20;
        }
        if (pageSize > 50) {
            pageSize = 50;
        }
    }
}
