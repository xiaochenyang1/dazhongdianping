package com.tuowei.dazhongdianping.module.openapi.model;

import java.time.LocalDateTime;

/**
 * 开放平台密钥。
 * secretHash 对应列 secret_hash：这是内部密钥库，保存的是原始 secret 明文，不做哈希，
 * 以便用同一份密钥校验 HMAC-SHA256。列表接口不得返回该字段。
 */
public class OpenApiKeyRow {
    private Long id;
    private Long appId;
    private String keyId;
    /** 内部密钥库中的原始 secret，不是摘要。 */
    private String secretHash;
    private Integer status;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getAppId() { return appId; }
    public void setAppId(Long appId) { this.appId = appId; }
    public String getKeyId() { return keyId; }
    public void setKeyId(String keyId) { this.keyId = keyId; }
    public String getSecretHash() { return secretHash; }
    public void setSecretHash(String secretHash) { this.secretHash = secretHash; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
