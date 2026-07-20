package com.tuowei.dazhongdianping.module.circle.model;

public class CircleRow {
    private Long id; private String region; private String name; private String description; private String coverUrl;
    private Integer memberCount; private Integer postCount; private Integer sort; private Integer status; private boolean joinedByCurrentUser;
    public Long getId() { return id; } public void setId(Long value) { id = value; }
    public String getRegion() { return region; } public void setRegion(String value) { region = value; }
    public String getName() { return name; } public void setName(String value) { name = value; }
    public String getDescription() { return description; } public void setDescription(String value) { description = value; }
    public String getCoverUrl() { return coverUrl; } public void setCoverUrl(String value) { coverUrl = value; }
    public Integer getMemberCount() { return memberCount; } public void setMemberCount(Integer value) { memberCount = value; }
    public Integer getPostCount() { return postCount; } public void setPostCount(Integer value) { postCount = value; }
    public Integer getSort() { return sort; } public void setSort(Integer value) { sort = value; }
    public Integer getStatus() { return status; } public void setStatus(Integer value) { status = value; }
    public boolean isJoinedByCurrentUser() { return joinedByCurrentUser; } public void setJoinedByCurrentUser(boolean value) { joinedByCurrentUser = value; }
}
