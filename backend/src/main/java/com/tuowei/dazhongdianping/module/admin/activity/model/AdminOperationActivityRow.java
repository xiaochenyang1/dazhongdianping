package com.tuowei.dazhongdianping.module.admin.activity.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminOperationActivityRow {

    private Long id;
    private String name;
    private String code;
    private String region;
    private Long cityId;
    private String cityName;
    private Integer channel;
    private Integer type;
    private Integer status;
    private String cover;
    private String landingUrl;
    private String ruleJson;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    private Integer itemCount;
    private Long createdBy;
    private Long updatedBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
