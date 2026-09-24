package com.tuowei.dazhongdianping.module.openapi.model;

import java.time.LocalDateTime;

/** 开放平台应用。 */
public class OpenAppRow {
    private Long id;
    private String region;
    private String name;
    private Long ownerMerchantId;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public Long getOwnerMerchantId() { return ownerMerchantId; }
    public void setOwnerMerchantId(Long ownerMerchantId) { this.ownerMerchantId = ownerMerchantId; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
