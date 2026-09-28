package com.tuowei.dazhongdianping.module.complaint.model;

import java.time.LocalDateTime;

/** 投诉工单行。 */
public class ComplaintTicketRow {
    private Long id;
    private String region;
    private String ticketNo;
    private Long userId;
    private Long shopId;
    private Long merchantId;
    private Long orderId;
    private Integer type;
    private String title;
    private String content;
    private Integer status;
    private String merchantReply;
    private LocalDateTime merchantRepliedAt;
    private String resolution;
    private Long resolvedBy;
    private LocalDateTime resolvedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    // 关联展示字段
    private String shopName;
    private String userNickname;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public String getTicketNo() { return ticketNo; }
    public void setTicketNo(String ticketNo) { this.ticketNo = ticketNo; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getShopId() { return shopId; }
    public void setShopId(Long shopId) { this.shopId = shopId; }
    public Long getMerchantId() { return merchantId; }
    public void setMerchantId(Long merchantId) { this.merchantId = merchantId; }
    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }
    public Integer getType() { return type; }
    public void setType(Integer type) { this.type = type; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public String getMerchantReply() { return merchantReply; }
    public void setMerchantReply(String merchantReply) { this.merchantReply = merchantReply; }
    public LocalDateTime getMerchantRepliedAt() { return merchantRepliedAt; }
    public void setMerchantRepliedAt(LocalDateTime merchantRepliedAt) { this.merchantRepliedAt = merchantRepliedAt; }
    public String getResolution() { return resolution; }
    public void setResolution(String resolution) { this.resolution = resolution; }
    public Long getResolvedBy() { return resolvedBy; }
    public void setResolvedBy(Long resolvedBy) { this.resolvedBy = resolvedBy; }
    public LocalDateTime getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(LocalDateTime resolvedAt) { this.resolvedAt = resolvedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }
    public String getUserNickname() { return userNickname; }
    public void setUserNickname(String userNickname) { this.userNickname = userNickname; }
}
