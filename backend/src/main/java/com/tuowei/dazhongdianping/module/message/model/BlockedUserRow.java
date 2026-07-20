package com.tuowei.dazhongdianping.module.message.model;

import java.time.LocalDateTime;

public class BlockedUserRow {
    private Long id; private String nickname; private String avatar; private LocalDateTime blockedAt;
    public Long getId() { return id; } public void setId(Long value) { id = value; }
    public String getNickname() { return nickname; } public void setNickname(String value) { nickname = value; }
    public String getAvatar() { return avatar; } public void setAvatar(String value) { avatar = value; }
    public LocalDateTime getBlockedAt() { return blockedAt; } public void setBlockedAt(LocalDateTime value) { blockedAt = value; }
}
