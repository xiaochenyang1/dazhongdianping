package com.tuowei.dazhongdianping.module.experiment.model;

import java.time.LocalDateTime;

/** 实验分组分配行。同一实验对同一用户只保留第一次结果。 */
public class ExperimentAssignmentRow {
    private Long id;
    private Long experimentId;
    private Long userId;
    private String variant;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getExperimentId() { return experimentId; }
    public void setExperimentId(Long experimentId) { this.experimentId = experimentId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getVariant() { return variant; }
    public void setVariant(String variant) { this.variant = variant; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
