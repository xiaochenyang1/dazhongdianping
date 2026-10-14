package com.tuowei.dazhongdianping.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/** EU launch switches stay disabled unless an operator explicitly enables them. */
@Data
@ConfigurationProperties(prefix = "app.launch.eu")
public class LaunchProperties {
    private boolean creatorRewardsEnabled;
    private boolean seckillEnabled;
    private boolean groupBuyEnabled;
}
