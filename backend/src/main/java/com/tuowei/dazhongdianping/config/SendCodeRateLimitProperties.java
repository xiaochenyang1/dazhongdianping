package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.auth.send-code-rate-limit")
public class SendCodeRateLimitProperties {

    private int accountShortWindowSeconds = 60;
    private int accountShortWindowMaxRequests = 1;
    private int accountLongWindowSeconds = 600;
    private int accountLongWindowMaxRequests = 5;
    private int deviceWindowSeconds = 600;
    private int deviceWindowMaxRequests = 3;
    private int ipWindowSeconds = 600;
    private int ipWindowMaxRequests = 10;

    public int getAccountShortWindowSeconds() {
        return accountShortWindowSeconds;
    }

    public void setAccountShortWindowSeconds(int accountShortWindowSeconds) {
        this.accountShortWindowSeconds = accountShortWindowSeconds;
    }

    public int getAccountShortWindowMaxRequests() {
        return accountShortWindowMaxRequests;
    }

    public void setAccountShortWindowMaxRequests(int accountShortWindowMaxRequests) {
        this.accountShortWindowMaxRequests = accountShortWindowMaxRequests;
    }

    public int getAccountLongWindowSeconds() {
        return accountLongWindowSeconds;
    }

    public void setAccountLongWindowSeconds(int accountLongWindowSeconds) {
        this.accountLongWindowSeconds = accountLongWindowSeconds;
    }

    public int getAccountLongWindowMaxRequests() {
        return accountLongWindowMaxRequests;
    }

    public void setAccountLongWindowMaxRequests(int accountLongWindowMaxRequests) {
        this.accountLongWindowMaxRequests = accountLongWindowMaxRequests;
    }

    public int getDeviceWindowSeconds() {
        return deviceWindowSeconds;
    }

    public void setDeviceWindowSeconds(int deviceWindowSeconds) {
        this.deviceWindowSeconds = deviceWindowSeconds;
    }

    public int getDeviceWindowMaxRequests() {
        return deviceWindowMaxRequests;
    }

    public void setDeviceWindowMaxRequests(int deviceWindowMaxRequests) {
        this.deviceWindowMaxRequests = deviceWindowMaxRequests;
    }

    public int getIpWindowSeconds() {
        return ipWindowSeconds;
    }

    public void setIpWindowSeconds(int ipWindowSeconds) {
        this.ipWindowSeconds = ipWindowSeconds;
    }

    public int getIpWindowMaxRequests() {
        return ipWindowMaxRequests;
    }

    public void setIpWindowMaxRequests(int ipWindowMaxRequests) {
        this.ipWindowMaxRequests = ipWindowMaxRequests;
    }
}
