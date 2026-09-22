package com.tuowei.dazhongdianping.module.consult.model;

import java.time.LocalDateTime;

/** 咨询会话行。 */
public class ConsultSessionRow {
    private Long id;
    private String region;
    private Long userId;
    private Long shopId;
    private Long merchantId;
    private String lastMessage;
    private LocalDateTime lastMessageAt;
    private Integer userUnread;
    private Integer merchantUnread;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    // 关联展示字段
    private String shopName;
    private String userNickname;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getShopId() { return shopId; }
    public void setShopId(Long shopId) { this.shopId = shopId; }
    public Long getMerchantId() { return merchantId; }
    public void setMerchantId(Long merchantId) { this.merchantId = merchantId; }
    public String getLastMessage() { return lastMessage; }
    public void setLastMessage(String lastMessage) { this.lastMessage = lastMessage; }
    public LocalDateTime getLastMessageAt() { return lastMessageAt; }
    public void setLastMessageAt(LocalDateTime lastMessageAt) { this.lastMessageAt = lastMessageAt; }
    public Integer getUserUnread() { return userUnread; }
    public void setUserUnread(Integer userUnread) { this.userUnread = userUnread; }
    public Integer getMerchantUnread() { return merchantUnread; }
    public void setMerchantUnread(Integer merchantUnread) { this.merchantUnread = merchantUnread; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }
    public String getUserNickname() { return userNickname; }
    public void setUserNickname(String userNickname) { this.userNickname = userNickname; }
}
