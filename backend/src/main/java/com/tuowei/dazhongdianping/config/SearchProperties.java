package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.search")
public class SearchProperties {

    private Provider provider = Provider.MYSQL;
    private String baseUrl = "http://127.0.0.1:9200";
    private String indexName = "dzdp_shop_v1";
    private boolean fallbackOnError = true;
    private int syncBatchSize = 50;
    private long syncLockTimeoutSeconds = 300;
    private long syncRetryBaseSeconds = 15;
    private long syncRetryMaxSeconds = 1800;

    public Provider getProvider() {
        return provider;
    }

    public void setProvider(Provider provider) {
        this.provider = provider;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String getIndexName() {
        return indexName;
    }

    public void setIndexName(String indexName) {
        this.indexName = indexName;
    }

    public boolean isFallbackOnError() {
        return fallbackOnError;
    }

    public void setFallbackOnError(boolean fallbackOnError) {
        this.fallbackOnError = fallbackOnError;
    }

    public int getSyncBatchSize() {
        return syncBatchSize;
    }

    public void setSyncBatchSize(int syncBatchSize) {
        this.syncBatchSize = syncBatchSize;
    }

    public long getSyncLockTimeoutSeconds() {
        return syncLockTimeoutSeconds;
    }

    public void setSyncLockTimeoutSeconds(long syncLockTimeoutSeconds) {
        this.syncLockTimeoutSeconds = syncLockTimeoutSeconds;
    }

    public long getSyncRetryBaseSeconds() {
        return syncRetryBaseSeconds;
    }

    public void setSyncRetryBaseSeconds(long syncRetryBaseSeconds) {
        this.syncRetryBaseSeconds = syncRetryBaseSeconds;
    }

    public long getSyncRetryMaxSeconds() {
        return syncRetryMaxSeconds;
    }

    public void setSyncRetryMaxSeconds(long syncRetryMaxSeconds) {
        this.syncRetryMaxSeconds = syncRetryMaxSeconds;
    }

    public enum Provider {
        MYSQL,
        ELASTICSEARCH
    }
}
