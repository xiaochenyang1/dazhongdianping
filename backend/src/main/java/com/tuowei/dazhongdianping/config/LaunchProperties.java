package com.tuowei.dazhongdianping.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/** Deferred features require deployment opt-in before any regional capability can open. */
@Data
@ConfigurationProperties(prefix = "app.launch")
public class LaunchProperties {
    private boolean deferredFeaturesEnabled;
    private final Eu eu = new Eu();

    @Data
    public static class Eu {
        private boolean creatorRewardsEnabled;
        private boolean seckillEnabled;
        private boolean groupBuyEnabled;
    }
}
