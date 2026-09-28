package com.tuowei.dazhongdianping.module.experiment.model;

import java.time.LocalDateTime;

/** 功能开关行。 */
public class FeatureFlagRow {
    private Long id;
    private String region;
    private String flagKey;
    private String description;
    private Boolean enabled;
    private Integer rolloutPercent;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public String getFlagKey() { return flagKey; }
    public void setFlagKey(String flagKey) { this.flagKey = flagKey; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Boolean getEnabled() { return enabled; }
    public void setEnabled(Boolean enabled) { this.enabled = enabled; }
    public Integer getRolloutPercent() { return rolloutPercent; }
    public void setRolloutPercent(Integer rolloutPercent) { this.rolloutPercent = rolloutPercent; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
