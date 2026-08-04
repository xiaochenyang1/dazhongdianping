package com.tuowei.dazhongdianping.module.points.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PointsProductRow {

    private Long id;
    private String region;
    private String name;
    private String coverImage;
    private String description;
    private Integer pointsPrice;
    private Integer stock;
    private Integer exchangeLimitPerUser;
    private Integer exchangeCount;
    private Integer fulfillType;
    private Integer status;
    private Integer sort;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Boolean isDeleted;
}
