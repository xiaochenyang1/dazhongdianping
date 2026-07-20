package com.tuowei.dazhongdianping.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.privacy")
public class PrivacyProperties {

    private String exportBaseDir = "local-storage/privacy-exports";
    private int exportExpireHours = 168;
    private int exportDailyLimit = 3;
    private int deleteCoolingOffDays = 7;

    public String getExportBaseDir() {
        return exportBaseDir;
    }

    public void setExportBaseDir(String exportBaseDir) {
        this.exportBaseDir = exportBaseDir;
    }

    public int getExportExpireHours() {
        return exportExpireHours;
    }

    public void setExportExpireHours(int exportExpireHours) {
        this.exportExpireHours = exportExpireHours;
    }

    public int getExportDailyLimit() {
        return exportDailyLimit;
    }

    public void setExportDailyLimit(int exportDailyLimit) {
        this.exportDailyLimit = exportDailyLimit;
    }

    public int getDeleteCoolingOffDays() {
        return deleteCoolingOffDays;
    }

    public void setDeleteCoolingOffDays(int deleteCoolingOffDays) {
        this.deleteCoolingOffDays = deleteCoolingOffDays;
    }
}
