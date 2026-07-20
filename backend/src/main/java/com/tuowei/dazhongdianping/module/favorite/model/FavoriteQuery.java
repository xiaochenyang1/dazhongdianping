package com.tuowei.dazhongdianping.module.favorite.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class FavoriteQuery {
    @Min(1) @Max(2) private Integer targetType;
    @Min(1) private Integer page = 1;
    @Min(1) @Max(50) private Integer pageSize = 12;
    private Long userId;
    private String region;
    public int getOffset() { return (page - 1) * pageSize; }
    public void normalize() { page = page == null || page < 1 ? 1 : page; pageSize = pageSize == null || pageSize < 1 ? 12 : Math.min(pageSize, 50); }
}
