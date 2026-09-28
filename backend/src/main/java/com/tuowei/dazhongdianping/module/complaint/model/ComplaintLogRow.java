package com.tuowei.dazhongdianping.module.complaint.model;

import java.time.LocalDateTime;

/** 投诉处理日志行。 */
public class ComplaintLogRow {
    private Long id;
    private Long ticketId;
    private Integer actorType;
    private Long actorId;
    private Integer action;
    private String remark;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getTicketId() { return ticketId; }
    public void setTicketId(Long ticketId) { this.ticketId = ticketId; }
    public Integer getActorType() { return actorType; }
    public void setActorType(Integer actorType) { this.actorType = actorType; }
    public Long getActorId() { return actorId; }
    public void setActorId(Long actorId) { this.actorId = actorId; }
    public Integer getAction() { return action; }
    public void setAction(Integer action) { this.action = action; }
    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
