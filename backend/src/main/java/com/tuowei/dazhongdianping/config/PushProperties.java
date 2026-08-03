package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.push")
public class PushProperties {

    private boolean enabled;
    private int maxAttempts = 3;
    private long initialBackoffMillis = 250;
    private Fcm fcm = new Fcm();
    private Apns apns = new Apns();

    public boolean isEnabled() {
        return enabled;
    }

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public int getMaxAttempts() {
        return maxAttempts;
    }

    public void setMaxAttempts(int maxAttempts) {
        this.maxAttempts = maxAttempts;
    }

    public long getInitialBackoffMillis() {
        return initialBackoffMillis;
    }

    public void setInitialBackoffMillis(long initialBackoffMillis) {
        this.initialBackoffMillis = initialBackoffMillis;
    }

    public Fcm getFcm() {
        return fcm;
    }

    public void setFcm(Fcm fcm) {
        this.fcm = fcm;
    }

    public Apns getApns() {
        return apns;
    }

    public void setApns(Apns apns) {
        this.apns = apns;
    }

    public static class Fcm {
        private String projectId = "";
        private String clientEmail = "";
        private String privateKey = "";
        private String tokenUrl = "https://oauth2.googleapis.com/token";
        private String apiBaseUrl = "https://fcm.googleapis.com";

        public String getProjectId() {
            return projectId;
        }

        public void setProjectId(String projectId) {
            this.projectId = projectId;
        }

        public String getClientEmail() {
            return clientEmail;
        }

        public void setClientEmail(String clientEmail) {
            this.clientEmail = clientEmail;
        }

        public String getPrivateKey() {
            return privateKey;
        }

        public void setPrivateKey(String privateKey) {
            this.privateKey = privateKey;
        }

        public String getTokenUrl() {
            return tokenUrl;
        }

        public void setTokenUrl(String tokenUrl) {
            this.tokenUrl = tokenUrl;
        }

        public String getApiBaseUrl() {
            return apiBaseUrl;
        }

        public void setApiBaseUrl(String apiBaseUrl) {
            this.apiBaseUrl = apiBaseUrl;
        }

        public boolean isConfigured() {
            return hasText(projectId) && hasText(clientEmail) && hasText(privateKey);
        }
    }

    public static class Apns {
        private String teamId = "";
        private String keyId = "";
        private String privateKey = "";
        private String topic = "";
        private String endpoint = "";
        private boolean production;

        public String getTeamId() {
            return teamId;
        }

        public void setTeamId(String teamId) {
            this.teamId = teamId;
        }

        public String getKeyId() {
            return keyId;
        }

        public void setKeyId(String keyId) {
            this.keyId = keyId;
        }

        public String getPrivateKey() {
            return privateKey;
        }

        public void setPrivateKey(String privateKey) {
            this.privateKey = privateKey;
        }

        public String getTopic() {
            return topic;
        }

        public void setTopic(String topic) {
            this.topic = topic;
        }

        public String getEndpoint() {
            return endpoint;
        }

        public void setEndpoint(String endpoint) {
            this.endpoint = endpoint;
        }

        public boolean isProduction() {
            return production;
        }

        public void setProduction(boolean production) {
            this.production = production;
        }

        public boolean isConfigured() {
            return hasText(teamId) && hasText(keyId) && hasText(privateKey) && hasText(topic);
        }
    }

    private static boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }
}
