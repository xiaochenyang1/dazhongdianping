package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.file-storage")
public class FileStorageProperties {

    private Provider provider = Provider.LOCAL;
    private String baseDir = "local-storage/uploads";
    private long maxImageBytes = 5L * 1024L * 1024L;
    private S3 s3 = new S3();

    public Provider getProvider() {
        return provider;
    }

    public void setProvider(Provider provider) {
        this.provider = provider;
    }

    public String getBaseDir() {
        return baseDir;
    }

    public void setBaseDir(String baseDir) {
        this.baseDir = baseDir;
    }

    public long getMaxImageBytes() {
        return maxImageBytes;
    }

    public void setMaxImageBytes(long maxImageBytes) {
        this.maxImageBytes = maxImageBytes;
    }

    public S3 getS3() {
        return s3;
    }

    public void setS3(S3 s3) {
        this.s3 = s3;
    }

    public enum Provider {
        LOCAL,
        S3
    }

    public static class S3 {

        private String bucket = "";
        private String region = "us-east-1";
        private String endpoint = "";
        private String publicBaseUrl = "";
        private String accessKey = "";
        private String secretKey = "";
        private boolean pathStyleAccessEnabled = false;

        public String getBucket() {
            return bucket;
        }

        public void setBucket(String bucket) {
            this.bucket = bucket;
        }

        public String getRegion() {
            return region;
        }

        public void setRegion(String region) {
            this.region = region;
        }

        public String getEndpoint() {
            return endpoint;
        }

        public void setEndpoint(String endpoint) {
            this.endpoint = endpoint;
        }

        public String getPublicBaseUrl() {
            return publicBaseUrl;
        }

        public void setPublicBaseUrl(String publicBaseUrl) {
            this.publicBaseUrl = publicBaseUrl;
        }

        public String getAccessKey() {
            return accessKey;
        }

        public void setAccessKey(String accessKey) {
            this.accessKey = accessKey;
        }

        public String getSecretKey() {
            return secretKey;
        }

        public void setSecretKey(String secretKey) {
            this.secretKey = secretKey;
        }

        public boolean isPathStyleAccessEnabled() {
            return pathStyleAccessEnabled;
        }

        public void setPathStyleAccessEnabled(boolean pathStyleAccessEnabled) {
            this.pathStyleAccessEnabled = pathStyleAccessEnabled;
        }
    }
}
