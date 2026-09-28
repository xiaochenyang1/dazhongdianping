package com.tuowei.dazhongdianping.module.adpromo.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** 广告投放计划行。 */
public class AdCampaignRow {
    private Long id;
    private String region;
    private Long merchantId;
    private Long shopId;
    private String name;
    private Integer slotType;
    private String keyword;
    private BigDecimal bidCpc;
    private BigDecimal dailyBudget;
    private BigDecimal spentToday;
    private LocalDate spendDate;
    private BigDecimal totalSpent;
    private Integer status;
    private Integer auditStatus;
    private String rejectReason;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    // 关联展示字段
    private String shopName;
    private String coverUrl;
    private java.math.BigDecimal score;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Long getMerchantId() { return merchantId; }
    public void setMerchantId(Long merchantId) { this.merchantId = merchantId; }
    public Long getShopId() { return shopId; }
    public void setShopId(Long shopId) { this.shopId = shopId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public Integer getSlotType() { return slotType; }
    public void setSlotType(Integer slotType) { this.slotType = slotType; }
    public String getKeyword() { return keyword; }
    public void setKeyword(String keyword) { this.keyword = keyword; }
    public BigDecimal getBidCpc() { return bidCpc; }
    public void setBidCpc(BigDecimal bidCpc) { this.bidCpc = bidCpc; }
    public BigDecimal getDailyBudget() { return dailyBudget; }
    public void setDailyBudget(BigDecimal dailyBudget) { this.dailyBudget = dailyBudget; }
    public BigDecimal getSpentToday() { return spentToday; }
    public void setSpentToday(BigDecimal spentToday) { this.spentToday = spentToday; }
    public LocalDate getSpendDate() { return spendDate; }
    public void setSpendDate(LocalDate spendDate) { this.spendDate = spendDate; }
    public BigDecimal getTotalSpent() { return totalSpent; }
    public void setTotalSpent(BigDecimal totalSpent) { this.totalSpent = totalSpent; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public Integer getAuditStatus() { return auditStatus; }
    public void setAuditStatus(Integer auditStatus) { this.auditStatus = auditStatus; }
    public String getRejectReason() { return rejectReason; }
    public void setRejectReason(String rejectReason) { this.rejectReason = rejectReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }
    public String getCoverUrl() { return coverUrl; }
    public void setCoverUrl(String coverUrl) { this.coverUrl = coverUrl; }
    public java.math.BigDecimal getScore() { return score; }
    public void setScore(java.math.BigDecimal score) { this.score = score; }
}
