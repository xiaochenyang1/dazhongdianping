package com.tuowei.dazhongdianping.module.experiment.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class FeatureFlagScopeRow {
    private Long id;
    private Long featureFlagId;
    private String scopeType;
    private Long scopeId;
    private Boolean enabled;
    private Integer rolloutPercent;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
