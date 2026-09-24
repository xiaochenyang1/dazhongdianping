package com.tuowei.dazhongdianping.module.riskcontrol.model;

import java.time.LocalDateTime;

/**
 * risk_event 表行模型。
 */
public class RiskEventRow {

    private Long id;
    private String region;
    private String scene;
    private Long userId;
    private String deviceFingerprint;
    private String ip;
    private Long bizId;
    private Integer riskScore;
    private Integer decision;
    private String hitRules;
    private String reason;
    private Integer disposeStatus;
    private String disposeRemark;
    private Long disposedBy;
    private LocalDateTime disposedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getRegion() {
        return region;
    }

    public void setRegion(String region) {
        this.region = region;
    }

    public String getScene() {
        return scene;
    }

    public void setScene(String scene) {
        this.scene = scene;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getDeviceFingerprint() {
        return deviceFingerprint;
    }

    public void setDeviceFingerprint(String deviceFingerprint) {
        this.deviceFingerprint = deviceFingerprint;
    }

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    public Long getBizId() {
        return bizId;
    }

    public void setBizId(Long bizId) {
        this.bizId = bizId;
    }

    public Integer getRiskScore() {
        return riskScore;
    }

    public void setRiskScore(Integer riskScore) {
        this.riskScore = riskScore;
    }

    public Integer getDecision() {
        return decision;
    }

    public void setDecision(Integer decision) {
        this.decision = decision;
    }

    public String getHitRules() {
        return hitRules;
    }

    public void setHitRules(String hitRules) {
        this.hitRules = hitRules;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public Integer getDisposeStatus() {
        return disposeStatus;
    }

    public void setDisposeStatus(Integer disposeStatus) {
        this.disposeStatus = disposeStatus;
    }

    public String getDisposeRemark() {
        return disposeRemark;
    }

    public void setDisposeRemark(String disposeRemark) {
        this.disposeRemark = disposeRemark;
    }

    public Long getDisposedBy() {
        return disposedBy;
    }

    public void setDisposedBy(Long disposedBy) {
        this.disposedBy = disposedBy;
    }

    public LocalDateTime getDisposedAt() {
        return disposedAt;
    }

    public void setDisposedAt(LocalDateTime disposedAt) {
        this.disposedAt = disposedAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
