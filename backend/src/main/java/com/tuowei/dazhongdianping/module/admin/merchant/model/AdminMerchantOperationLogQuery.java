package com.tuowei.dazhongdianping.module.admin.merchant.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class AdminMerchantOperationLogQuery {

    @Min(value = 1, message = "operatorId 最小为 1")
    private Long operatorId;

    private String action;
    private String targetType;
    private String keyword;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 50, message = "pageSize 最大为 50")
    private Integer pageSize = 20;

    public int getOffset() {
        return (page - 1) * pageSize;
    }

    public void normalize() {
        action = normalizeText(action);
        targetType = normalizeText(targetType);
        keyword = normalizeText(keyword);
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

    private String normalizeText(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }
}
