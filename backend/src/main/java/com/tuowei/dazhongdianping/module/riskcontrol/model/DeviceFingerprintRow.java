package com.tuowei.dazhongdianping.module.riskcontrol.model;

/**
 * device_fingerprint 表行模型（仅取评估与画像所需字段）。
 */
public class DeviceFingerprintRow {

    private Long id;
    private Integer userCount;
    private Boolean blocked;
    private Long lastUserId;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Integer getUserCount() {
        return userCount;
    }

    public void setUserCount(Integer userCount) {
        this.userCount = userCount;
    }

    public Boolean getBlocked() {
        return blocked;
    }

    public void setBlocked(Boolean blocked) {
        this.blocked = blocked;
    }

    public Long getLastUserId() {
        return lastUserId;
    }

    public void setLastUserId(Long lastUserId) {
        this.lastUserId = lastUserId;
    }
}
