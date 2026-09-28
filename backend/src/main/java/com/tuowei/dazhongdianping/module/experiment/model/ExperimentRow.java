package com.tuowei.dazhongdianping.module.experiment.model;

import java.time.LocalDateTime;

/** 实验行。 */
public class ExperimentRow {
    private Long id;
    private String region;
    private String name;
    private String flagKey;
    private Integer status;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getFlagKey() { return flagKey; }
    public void setFlagKey(String flagKey) { this.flagKey = flagKey; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
