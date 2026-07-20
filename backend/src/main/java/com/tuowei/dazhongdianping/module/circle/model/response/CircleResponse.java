package com.tuowei.dazhongdianping.module.circle.model.response;

public record CircleResponse(Long id, String region, String name, String description, String coverUrl,
                             int memberCount, int postCount, int sort, int status, boolean joinedByCurrentUser) {}
