package com.tuowei.dazhongdianping.module.social.model.response;

public record FollowStatusResponse(Long userId, boolean following, long followerCount) {}
