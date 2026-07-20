package com.tuowei.dazhongdianping.module.message.model.response;

public record ConversationResponse(Long id, Long peerUserId, String peerNickname, String peerAvatar,
                                   String lastMessagePreview, String lastMessageAt, long unreadCount) {}
