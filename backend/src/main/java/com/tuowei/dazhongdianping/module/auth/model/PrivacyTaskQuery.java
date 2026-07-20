package com.tuowei.dazhongdianping.module.auth.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class PrivacyTaskQuery {

    private Long userId;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 50, message = "pageSize 最大为 50")
    private Integer pageSize = 10;

    public int getOffset() {
        return (page - 1) * pageSize;
    }

    public void normalize() {
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
