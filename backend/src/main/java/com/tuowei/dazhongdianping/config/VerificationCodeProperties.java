package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.auth.verification-code")
public class VerificationCodeProperties {

    private boolean mockEnabled;
    private String mockCode = "";
    private boolean exposeMockCode;
    private boolean devConsoleEnabled;
    private Mail mail = new Mail();
    private Twilio twilio = new Twilio();
    private Aliyun aliyun = new Aliyun();

    public boolean isMockEnabled() {
        return mockEnabled;
    }

    public void setMockEnabled(boolean mockEnabled) {
        this.mockEnabled = mockEnabled;
    }

    public String getMockCode() {
        return mockCode;
    }

    public void setMockCode(String mockCode) {
        this.mockCode = mockCode;
    }

    public boolean isExposeMockCode() {
        return exposeMockCode;
    }

    public void setExposeMockCode(boolean exposeMockCode) {
        this.exposeMockCode = exposeMockCode;
    }

    public boolean isDevConsoleEnabled() {
        return devConsoleEnabled;
    }

    public void setDevConsoleEnabled(boolean devConsoleEnabled) {
        this.devConsoleEnabled = devConsoleEnabled;
    }

    public Mail getMail() {
        return mail;
    }

    public void setMail(Mail mail) {
        this.mail = mail;
    }

    public Twilio getTwilio() {
        return twilio;
    }

    public void setTwilio(Twilio twilio) {
        this.twilio = twilio;
    }

    public Aliyun getAliyun() {
        return aliyun;
    }

    public void setAliyun(Aliyun aliyun) {
        this.aliyun = aliyun;
    }

    public static class Mail {
        private boolean enabled;
        private String host = "";
        private String from = "";
        private String subject = "Your verification code";
        private String brandName = "Dazhongdianping";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getHost() {
            return host;
        }

        public void setHost(String host) {
            this.host = host;
        }

        public String getFrom() {
            return from;
        }

        public void setFrom(String from) {
            this.from = from;
        }

        public String getSubject() {
            return subject;
        }

        public void setSubject(String subject) {
            this.subject = subject;
        }

        public String getBrandName() {
            return brandName;
        }

        public void setBrandName(String brandName) {
            this.brandName = brandName;
        }

        public boolean isConfigured() {
            return enabled && hasText(host) && hasText(from) && hasText(subject);
        }
    }

    public static class Twilio {
        private boolean enabled;
        private String accountSid = "";
        private String authToken = "";
        private String from = "";
        private String messagingServiceSid = "";
        private String apiBaseUrl = "https://api.twilio.com";
        private String routePrefixes = "*";
        private String excludedRoutePrefixes = "+86";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getAccountSid() {
            return accountSid;
        }

        public void setAccountSid(String accountSid) {
            this.accountSid = accountSid;
        }

        public String getAuthToken() {
            return authToken;
        }

        public void setAuthToken(String authToken) {
            this.authToken = authToken;
        }

        public String getFrom() {
            return from;
        }

        public void setFrom(String from) {
            this.from = from;
        }

        public String getMessagingServiceSid() {
            return messagingServiceSid;
        }

        public void setMessagingServiceSid(String messagingServiceSid) {
            this.messagingServiceSid = messagingServiceSid;
        }

        public String getApiBaseUrl() {
            return apiBaseUrl;
        }

        public void setApiBaseUrl(String apiBaseUrl) {
            this.apiBaseUrl = apiBaseUrl;
        }

        public String getRoutePrefixes() {
            return routePrefixes;
        }

        public void setRoutePrefixes(String routePrefixes) {
            this.routePrefixes = routePrefixes;
        }

        public String getExcludedRoutePrefixes() {
            return excludedRoutePrefixes;
        }

        public void setExcludedRoutePrefixes(String excludedRoutePrefixes) {
            this.excludedRoutePrefixes = excludedRoutePrefixes;
        }

        public boolean isConfigured() {
            return enabled
                    && hasText(accountSid)
                    && hasText(authToken)
                    && hasText(apiBaseUrl)
                    && (hasText(from) || hasText(messagingServiceSid));
        }
    }

    public static class Aliyun {
        private boolean enabled;
        private String accessKeyId = "";
        private String accessKeySecret = "";
        private String signName = "";
        private String templateCode = "";
        private String endpoint = "https://dysmsapi.aliyuncs.com";
        private String regionId = "cn-hangzhou";
        private String routePrefixes = "+86";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getAccessKeyId() {
            return accessKeyId;
        }

        public void setAccessKeyId(String accessKeyId) {
            this.accessKeyId = accessKeyId;
        }

        public String getAccessKeySecret() {
            return accessKeySecret;
        }

        public void setAccessKeySecret(String accessKeySecret) {
            this.accessKeySecret = accessKeySecret;
        }

        public String getSignName() {
            return signName;
        }

        public void setSignName(String signName) {
            this.signName = signName;
        }

        public String getTemplateCode() {
            return templateCode;
        }

        public void setTemplateCode(String templateCode) {
            this.templateCode = templateCode;
        }

        public String getEndpoint() {
            return endpoint;
        }

        public void setEndpoint(String endpoint) {
            this.endpoint = endpoint;
        }

        public String getRegionId() {
            return regionId;
        }

        public void setRegionId(String regionId) {
            this.regionId = regionId;
        }

        public String getRoutePrefixes() {
            return routePrefixes;
        }

        public void setRoutePrefixes(String routePrefixes) {
            this.routePrefixes = routePrefixes;
        }

        public boolean isConfigured() {
            return enabled
                    && hasText(accessKeyId)
                    && hasText(accessKeySecret)
                    && hasText(signName)
                    && hasText(templateCode)
                    && hasText(endpoint)
                    && hasText(regionId)
                    && hasText(routePrefixes);
        }
    }

    private static boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }
}
