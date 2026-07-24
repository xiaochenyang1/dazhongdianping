package com.tuowei.dazhongdianping.module.admin.user.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.Locale;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class AdminAppUserQuery {

    private String keyword;

    @Min(value = 1, message = "userId 最小为 1")
    private Long userId;

    @Min(value = 1, message = "status 最小为 1")
    @Max(value = 3, message = "status 最大为 3")
    private Integer status;

    private String preferredRegion;

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
        if (StringUtils.hasText(preferredRegion)) {
            String region = preferredRegion.trim().toUpperCase(Locale.ROOT);
            if (!"CN".equals(region) && !"EU".equals(region)) {
                throw new IllegalArgumentException("preferredRegion 只支持 CN 或 EU");
            }
            preferredRegion = region;
        } else {
            preferredRegion = null;
        }
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
