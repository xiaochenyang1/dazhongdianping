package com.tuowei.dazhongdianping.module.browse.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;
import java.util.Locale;
import lombok.Data;
import org.springframework.util.StringUtils;

@Data
public class ShopListQuery {

    private String region;
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
    private Double north;
    private Double south;
    private Double east;
    private Double west;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 50, message = "pageSize 最大为 50")
    private Integer pageSize = 12;

    public int getOffset() {
        return (page - 1) * pageSize;
    }

    public void normalize() {
        if (!StringUtils.hasText(sort)) {
            sort = "smart";
        }
        sort = sort.toLowerCase(Locale.ROOT);
        if (!java.util.Set.of("smart", "distance", "score", "popular").contains(sort)) {
            throw new IllegalArgumentException("sort 只支持 smart/distance/score/popular");
        }
        if (page == null || page < 1) {
            page = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 12;
        }
        if (pageSize > 50) {
            pageSize = 50;
        }
        if (!StringUtils.hasText(keyword)) {
            keyword = null;
        } else {
            keyword = keyword.trim();
        }
        validateCoordinates();
    }

    private void validateCoordinates() {
        if ("distance".equals(sort) && (lat == null || lng == null)) {
            throw new IllegalArgumentException("距离排序必须提供 lat 和 lng");
        }
        if (lat != null && (!Double.isFinite(lat) || lat < -90 || lat > 90)) {
            throw new IllegalArgumentException("lat 必须在 -90 到 90 之间");
        }
        if (lng != null && (!Double.isFinite(lng) || lng < -180 || lng > 180)) {
            throw new IllegalArgumentException("lng 必须在 -180 到 180 之间");
        }
        int boundsCount = (north == null ? 0 : 1)
                + (south == null ? 0 : 1)
                + (east == null ? 0 : 1)
                + (west == null ? 0 : 1);
        if (boundsCount != 0 && boundsCount != 4) {
            throw new IllegalArgumentException("地图边界必须同时提供 north、south、east 和 west");
        }
        if (boundsCount == 0) {
            return;
        }
        if (!Double.isFinite(north) || north < -90 || north > 90
                || !Double.isFinite(south) || south < -90 || south > 90) {
            throw new IllegalArgumentException("north 和 south 必须在 -90 到 90 之间");
        }
        if (!Double.isFinite(east) || east < -180 || east > 180
                || !Double.isFinite(west) || west < -180 || west > 180) {
            throw new IllegalArgumentException("east 和 west 必须在 -180 到 180 之间");
        }
        if (north < south) {
            throw new IllegalArgumentException("north 不能小于 south");
        }
    }
}
