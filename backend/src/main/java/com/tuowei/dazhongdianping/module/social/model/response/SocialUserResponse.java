package com.tuowei.dazhongdianping.module.social.model.response;

public record SocialUserResponse(Long id, String nickname, String avatar, String signature, Integer level,
                                 Long followerCount, boolean followedByCurrentUser, String followedAt) {}
