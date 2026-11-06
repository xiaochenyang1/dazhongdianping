package com.tuowei.dazhongdianping.module.creator.model;

import java.time.LocalDateTime;

/** 创作者任务领取行。status 1 已领取，2 已发奖，3 待审核，4 已驳回。 */
public class CreatorClaimRow {
    private Long id;
    private Long taskId;
    private Long userId;
    private String region;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTaskId() { return taskId; }
    public void setTaskId(Long taskId) { this.taskId = taskId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }

    private String taskTitle;
    public String getTaskTitle() { return taskTitle; }
    public void setTaskTitle(String value) { this.taskTitle = value; }
    private String taskDescription;
    public String getTaskDescription() { return taskDescription; }
    public void setTaskDescription(String value) { this.taskDescription = value; }
    private Integer rewardPoints;
    public Integer getRewardPoints() { return rewardPoints; }
    public void setRewardPoints(Integer value) { this.rewardPoints = value; }
    private String evidenceType;
    public String getEvidenceType() { return evidenceType; }
    public void setEvidenceType(String value) { this.evidenceType = value; }
    private Long evidenceId;
    public Long getEvidenceId() { return evidenceId; }
    public void setEvidenceId(Long value) { this.evidenceId = value; }
    private String submissionNote;
    public String getSubmissionNote() { return submissionNote; }
    public void setSubmissionNote(String value) { this.submissionNote = value; }
    private Integer submissionVersion;
    public Integer getSubmissionVersion() { return submissionVersion; }
    public void setSubmissionVersion(Integer value) { this.submissionVersion = value; }
    private java.time.LocalDateTime submittedAt;
    public java.time.LocalDateTime getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(java.time.LocalDateTime value) { this.submittedAt = value; }
    private String reviewNote;
    public String getReviewNote() { return reviewNote; }
    public void setReviewNote(String value) { this.reviewNote = value; }
    private Long reviewedBy;
    public Long getReviewedBy() { return reviewedBy; }
    public void setReviewedBy(Long value) { this.reviewedBy = value; }
    private java.time.LocalDateTime reviewedAt;
    public java.time.LocalDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(java.time.LocalDateTime value) { this.reviewedAt = value; }
}
