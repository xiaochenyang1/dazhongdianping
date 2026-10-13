package com.tuowei.dazhongdianping.module.message.model.response;

public record MessageResponse(Long id, Long conversationId, Long fromUserId, Long toUserId,
                              String content, Integer status, boolean read, String readAt, String createdAt) {}
