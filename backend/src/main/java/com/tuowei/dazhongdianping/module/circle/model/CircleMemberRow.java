package com.tuowei.dazhongdianping.module.circle.model;

import java.time.LocalDateTime;

public class CircleMemberRow {
    private Long id; private String nickname; private String avatar; private String signature; private Integer level; private LocalDateTime joinedAt;
    public Long getId() { return id; } public void setId(Long value) { id = value; }
    public String getNickname() { return nickname; } public void setNickname(String value) { nickname = value; }
    public String getAvatar() { return avatar; } public void setAvatar(String value) { avatar = value; }
    public String getSignature() { return signature; } public void setSignature(String value) { signature = value; }
    public Integer getLevel() { return level; } public void setLevel(Integer value) { level = value; }
    public LocalDateTime getJoinedAt() { return joinedAt; } public void setJoinedAt(LocalDateTime value) { joinedAt = value; }
}
