package com.tuowei.dazhongdianping.module.admin.management.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class AdminImportBatchQuery {

    private String region;
    private Integer status;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 100, message = "pageSize 最大为 100")
    private Integer pageSize = 20;

    public void normalize() {
        if (page == null || page < 1) {
            page = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 20;
        }
        if (pageSize > 100) {
            pageSize = 100;
        }
    }

    public int getOffset() {
        return (page - 1) * pageSize;
    }
}
