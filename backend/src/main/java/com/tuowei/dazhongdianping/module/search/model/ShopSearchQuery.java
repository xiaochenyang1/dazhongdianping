package com.tuowei.dazhongdianping.module.search.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;
import java.util.Locale;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class ShopSearchQuery {

    private Long categoryId;
    private Long cityId;
    private Long areaId;
    private String keyword;
    private BigDecimal minPrice;
    private BigDecimal maxPrice;
    private BigDecimal minScore;
    private Boolean hasDeal;
    private Boolean openNow;
    private String sort = "smart";
    private Double lat;
    private Double lng;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 50, message = "pageSize 最大为 50")
    private Integer pageSize = 12;

    public int getOffset() {
        return (page - 1) * pageSize;
    }

    public void normalize() {
        keyword = StringUtils.hasText(keyword) ? keyword.trim() : null;
        sort = StringUtils.hasText(sort) ? sort.trim().toLowerCase(Locale.ROOT) : "smart";
        if (!ListSorts.SUPPORTED.contains(sort)) {
            throw new IllegalArgumentException("sort 只支持 smart/distance/score/popular");
        }
        page = page == null || page < 1 ? 1 : page;
        pageSize = pageSize == null || pageSize < 1 ? 12 : Math.min(pageSize, 50);
        if ("distance".equals(sort) && (lat == null || lng == null)) {
            throw new IllegalArgumentException("距离排序必须提供 lat 和 lng");
        }
        if (lat != null && (lat < -90 || lat > 90)) {
            throw new IllegalArgumentException("lat 必须在 -90 到 90 之间");
        }
        if (lng != null && (lng < -180 || lng > 180)) {
            throw new IllegalArgumentException("lng 必须在 -180 到 180 之间");
        }
        if (minPrice != null && maxPrice != null && minPrice.compareTo(maxPrice) > 0) {
            throw new IllegalArgumentException("minPrice 不能大于 maxPrice");
        }
    }

    private static final class ListSorts {
        private static final java.util.Set<String> SUPPORTED = java.util.Set.of(
                "smart", "distance", "score", "popular"
        );

        private ListSorts() {
        }
    }
}
