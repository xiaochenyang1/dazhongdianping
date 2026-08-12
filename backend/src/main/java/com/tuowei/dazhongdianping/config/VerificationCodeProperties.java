package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.auth.verification-code")
public class VerificationCodeProperties {

    private boolean mockEnabled;
    private String mockCode = "";
    private boolean exposeMockCode;
    private boolean devConsoleEnabled;

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
}
