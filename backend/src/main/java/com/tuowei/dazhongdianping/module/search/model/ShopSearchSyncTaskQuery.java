package com.tuowei.dazhongdianping.module.search.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.util.Locale;
import java.util.Set;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class ShopSearchSyncTaskQuery {

    private static final Set<String> ALLOWED_STATES = Set.of(
            "pending", "processing", "retrying", "stale"
    );

    @Size(max = 100, message = "keyword 最长为 100 个字符")
    private String keyword;

    @Size(max = 16, message = "state 最长为 16 个字符")
    private String state;

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
        state = StringUtils.hasText(state) ? state.trim().toLowerCase(Locale.ROOT) : null;
        if (state != null && !ALLOWED_STATES.contains(state)) {
            throw new IllegalArgumentException("state 仅支持 pending、processing、retrying 或 stale");
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
