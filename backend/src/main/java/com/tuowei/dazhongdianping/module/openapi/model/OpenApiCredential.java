package com.tuowei.dazhongdianping.module.openapi.model;

/**
 * 验签时读出的密钥与应用状态。secretHash 是内部密钥库里的原始 secret。
 */
public class OpenApiCredential {
    private String keyId;
    private String secretHash;
    private Integer status;
    private Long appId;
    private String region;
    private Integer appStatus;

    public String getKeyId() { return keyId; }
    public void setKeyId(String keyId) { this.keyId = keyId; }
    public String getSecretHash() { return secretHash; }
    public void setSecretHash(String secretHash) { this.secretHash = secretHash; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public Long getAppId() { return appId; }
    public void setAppId(Long appId) { this.appId = appId; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Integer getAppStatus() { return appStatus; }
    public void setAppStatus(Integer appStatus) { this.appStatus = appStatus; }
}
