package com.tuowei.dazhongdianping.module.waitlist.model;

import java.time.LocalDateTime;

/** 排队候位行。 */
public class WaitlistEntryRow {
    private Long id;
    private String region;
    private Long shopId;
    private Long merchantId;
    private Long userId;
    private Integer tableType;
    private Integer partySize;
    private Integer queueNo;
    private Integer status;
    private LocalDateTime calledAt;
    private LocalDateTime seatedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    // 关联展示字段
    private String shopName;
    private String userNickname;
    // 计算字段：前面还有多少桌
    private Integer aheadCount;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Long getShopId() { return shopId; }
    public void setShopId(Long shopId) { this.shopId = shopId; }
    public Long getMerchantId() { return merchantId; }
    public void setMerchantId(Long merchantId) { this.merchantId = merchantId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Integer getTableType() { return tableType; }
    public void setTableType(Integer tableType) { this.tableType = tableType; }
    public Integer getPartySize() { return partySize; }
    public void setPartySize(Integer partySize) { this.partySize = partySize; }
    public Integer getQueueNo() { return queueNo; }
    public void setQueueNo(Integer queueNo) { this.queueNo = queueNo; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCalledAt() { return calledAt; }
    public void setCalledAt(LocalDateTime calledAt) { this.calledAt = calledAt; }
    public LocalDateTime getSeatedAt() { return seatedAt; }
    public void setSeatedAt(LocalDateTime seatedAt) { this.seatedAt = seatedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }
    public String getUserNickname() { return userNickname; }
    public void setUserNickname(String userNickname) { this.userNickname = userNickname; }
    public Integer getAheadCount() { return aheadCount; }
    public void setAheadCount(Integer aheadCount) { this.aheadCount = aheadCount; }
}
