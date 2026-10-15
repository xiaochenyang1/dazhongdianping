package com.tuowei.dazhongdianping.module.launch;

import static org.assertj.core.api.Assertions.assertThat;

import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.config.LaunchProperties;
import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

class LaunchConfigurationTest {
    @Configuration(proxyBeanMethods = false)
    @EnableConfigurationProperties(LaunchProperties.class)
    @Import(LaunchPolicy.class)
    static class Config {}

    @Test
    void deferredCapabilitiesDefaultToClosedInEveryRegion() {
        new ApplicationContextRunner().withUserConfiguration(Config.class)
                .run(context -> {
                    for (Region region : Region.values()) {
                        assertThat(context.getBean(LaunchPolicy.class).capabilities(region))
                                .isEqualTo(new LaunchPolicy.Capabilities(region.name(), false, false, false));
                    }
                });
    }

    @Test
    void deploymentSwitchOverridesEnabledRegionalCapabilities() {
        new ApplicationContextRunner().withUserConfiguration(Config.class)
                .withPropertyValues("app.launch.deferred-features-enabled=false",
                        "app.launch.eu.creator-rewards-enabled=true",
                        "app.launch.eu.seckill-enabled=true",
                        "app.launch.eu.group-buy-enabled=true")
                .run(context -> {
                    for (Region region : Region.values()) {
                        assertThat(context.getBean(LaunchPolicy.class).capabilities(region))
                                .isEqualTo(new LaunchPolicy.Capabilities(region.name(), false, false, false));
                    }
                });
    }

    @Test
    void explicitDeploymentOptInPreservesCnCompatibilityAndEuRestrictions() {
        new ApplicationContextRunner().withUserConfiguration(Config.class)
                .withPropertyValues("app.launch.deferred-features-enabled=true")
                .run(context -> {
                    var policy = context.getBean(LaunchPolicy.class);
                    assertThat(policy.capabilities(Region.CN))
                            .isEqualTo(new LaunchPolicy.Capabilities("CN", true, true, true));
                    assertThat(policy.capabilities(Region.EU))
                            .isEqualTo(new LaunchPolicy.Capabilities("EU", false, false, false));
                });
    }

    @Test
    void enablesEachEuCapabilityIndependentlyFromExplicitConfiguration() {
        for (String property : new String[]{"creator-rewards", "seckill", "group-buy"}) {
            new ApplicationContextRunner().withUserConfiguration(Config.class)
                    .withPropertyValues("app.launch.deferred-features-enabled=true",
                            "app.launch.eu." + property + "-enabled=true")
                    .run(context -> {
                        var eu = context.getBean(LaunchPolicy.class).capabilities(Region.EU);
                        assertThat(eu.creatorRewards()).isEqualTo(property.equals("creator-rewards"));
                        assertThat(eu.seckill()).isEqualTo(property.equals("seckill"));
                        assertThat(eu.groupBuy()).isEqualTo(property.equals("group-buy"));
                    });
        }
    }
}
