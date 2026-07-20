package com.tuowei.dazhongdianping.module.message.model;

import java.time.LocalDateTime;

public class MessageRow {
    private Long id; private Long conversationId; private Long fromUserId; private Long toUserId;
    private String content; private boolean read; private LocalDateTime readAt; private LocalDateTime createdAt;
    public Long getId() { return id; } public void setId(Long id) { this.id = id; }
    public Long getConversationId() { return conversationId; } public void setConversationId(Long value) { conversationId = value; }
    public Long getFromUserId() { return fromUserId; } public void setFromUserId(Long value) { fromUserId = value; }
    public Long getToUserId() { return toUserId; } public void setToUserId(Long value) { toUserId = value; }
    public String getContent() { return content; } public void setContent(String value) { content = value; }
    public boolean isRead() { return read; } public void setRead(boolean value) { read = value; }
    public LocalDateTime getReadAt() { return readAt; } public void setReadAt(LocalDateTime value) { readAt = value; }
    public LocalDateTime getCreatedAt() { return createdAt; } public void setCreatedAt(LocalDateTime value) { createdAt = value; }
}
