package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class GrowthRuleRow {
    private Long id;
    private String action;
    private String actionName;
    private Integer growthValue;
    private Integer points;
    private Integer dailyLimit;
    private Boolean enabled;
    private LocalDateTime updatedAt;
}
