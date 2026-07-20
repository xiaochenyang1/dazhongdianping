package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;

public class FollowExportRow {
    private Long userId;
    private String nickname;
    private LocalDateTime followedAt;
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public LocalDateTime getFollowedAt() { return followedAt; }
    public void setFollowedAt(LocalDateTime followedAt) { this.followedAt = followedAt; }
}
