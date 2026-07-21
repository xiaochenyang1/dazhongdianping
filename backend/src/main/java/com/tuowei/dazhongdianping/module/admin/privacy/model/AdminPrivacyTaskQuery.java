package com.tuowei.dazhongdianping.module.admin.privacy.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class AdminPrivacyTaskQuery {

    private Long userId;
    private Integer taskType;
    private Integer status;
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
