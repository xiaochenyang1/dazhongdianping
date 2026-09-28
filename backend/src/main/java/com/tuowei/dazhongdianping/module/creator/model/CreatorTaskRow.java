package com.tuowei.dazhongdianping.module.creator.model;

import java.time.LocalDateTime;

/** 创作者任务行。claimStatus/claimId 仅 C 端联表时有值。 */
public class CreatorTaskRow {
    private Long id;
    private String region;
    private String title;
    private String description;
    private Integer rewardPoints;
    private Integer status;
    private LocalDateTime createdAt;
    private Integer claimStatus;
    private Long claimId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Integer getRewardPoints() { return rewardPoints; }
    public void setRewardPoints(Integer rewardPoints) { this.rewardPoints = rewardPoints; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public Integer getClaimStatus() { return claimStatus; }
    public void setClaimStatus(Integer claimStatus) { this.claimStatus = claimStatus; }
    public Long getClaimId() { return claimId; }
    public void setClaimId(Long claimId) { this.claimId = claimId; }
}
