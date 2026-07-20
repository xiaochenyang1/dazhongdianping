package com.tuowei.dazhongdianping.module.admin.audit.model;

import java.util.List;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class AdminAuditTaskQuery {

    private String region;
    private Integer bizType;
    private Integer status;
    private List<Integer> allowedBizTypes;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 50, message = "pageSize 最大为 50")
    private Integer pageSize = 10;

    public int getOffset() {
        return (page - 1) * pageSize;
    }

    public void normalize() {
        if (!StringUtils.hasText(region)) {
            region = null;
        } else {
            region = region.trim().toUpperCase();
        }
        if (page == null || page < 1) {
            page = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 10;
        }
        if (pageSize > 50) {
            pageSize = 50;
        }
    }
}
