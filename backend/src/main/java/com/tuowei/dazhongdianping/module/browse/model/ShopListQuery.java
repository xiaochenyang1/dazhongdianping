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
    }
}
