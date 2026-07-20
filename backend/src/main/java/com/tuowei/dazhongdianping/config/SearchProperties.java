package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.search")
public class SearchProperties {

    private Provider provider = Provider.MYSQL;
    private String baseUrl = "http://127.0.0.1:9200";
    private String indexName = "dzdp_shop_v1";
    private boolean fallbackOnError = true;

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

    public enum Provider {
        MYSQL,
        ELASTICSEARCH
    }
}
