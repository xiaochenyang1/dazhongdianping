package com.tuowei.dazhongdianping.module.consult.model;

import java.time.LocalDateTime;

/** 咨询消息行。 */
public class ConsultMessageRow {
    private Long id;
    private Long sessionId;
    private String region;
    private Integer senderType;
    private Long senderId;
    private String content;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getSessionId() { return sessionId; }
    public void setSessionId(Long sessionId) { this.sessionId = sessionId; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Integer getSenderType() { return senderType; }
    public void setSenderType(Integer senderType) { this.senderType = senderType; }
    public Long getSenderId() { return senderId; }
    public void setSenderId(Long senderId) { this.senderId = senderId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
