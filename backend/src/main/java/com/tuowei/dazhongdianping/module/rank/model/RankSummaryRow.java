package com.tuowei.dazhongdianping.module.rank.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class RankSummaryRow {
    private Long id;
    private String name;
    private Integer type;
    private String region;
    private Long cityId;
    private String cityName;
    private Long categoryId;
    private String categoryName;
    private Long configId;
    private String period;
    private Integer itemCount;
    private String coverUrl;
    private String topShopName;
    private LocalDateTime updatedAt;
}
