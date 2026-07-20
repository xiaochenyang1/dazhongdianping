package com.tuowei.dazhongdianping.module.auth.model;

public class TopicFollowExportRow {
    private Long id;
    private String name;
    private String region;
    private String followedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public String getFollowedAt() { return followedAt; }
    public void setFollowedAt(String followedAt) { this.followedAt = followedAt; }
}
