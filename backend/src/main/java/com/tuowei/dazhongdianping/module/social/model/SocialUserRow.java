package com.tuowei.dazhongdianping.module.social.model;

import java.time.LocalDateTime;

public class SocialUserRow {
    private Long id;
    private String nickname;
    private String avatar;
    private String signature;
    private Integer level;
    private Long followerCount;
    private LocalDateTime followedAt;
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }
    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }
    public String getSignature() { return signature; }
    public void setSignature(String signature) { this.signature = signature; }
    public Integer getLevel() { return level; }
    public void setLevel(Integer level) { this.level = level; }
    public Long getFollowerCount() { return followerCount; }
    public void setFollowerCount(Long followerCount) { this.followerCount = followerCount; }
    public LocalDateTime getFollowedAt() { return followedAt; }
    public void setFollowedAt(LocalDateTime followedAt) { this.followedAt = followedAt; }
}
