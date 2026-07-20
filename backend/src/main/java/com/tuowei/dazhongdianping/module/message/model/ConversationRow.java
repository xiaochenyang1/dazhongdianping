package com.tuowei.dazhongdianping.module.message.model;

import java.time.LocalDateTime;

public class ConversationRow {
    private Long id; private Long peerUserId; private String peerNickname; private String peerAvatar;
    private String lastMessagePreview; private LocalDateTime lastMessageAt; private long unreadCount;
    public Long getId() { return id; } public void setId(Long value) { id = value; }
    public Long getPeerUserId() { return peerUserId; } public void setPeerUserId(Long value) { peerUserId = value; }
    public String getPeerNickname() { return peerNickname; } public void setPeerNickname(String value) { peerNickname = value; }
    public String getPeerAvatar() { return peerAvatar; } public void setPeerAvatar(String value) { peerAvatar = value; }
    public String getLastMessagePreview() { return lastMessagePreview; } public void setLastMessagePreview(String value) { lastMessagePreview = value; }
    public LocalDateTime getLastMessageAt() { return lastMessageAt; } public void setLastMessageAt(LocalDateTime value) { lastMessageAt = value; }
    public long getUnreadCount() { return unreadCount; } public void setUnreadCount(long value) { unreadCount = value; }
}
