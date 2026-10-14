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
    void enablesEachEuCapabilityIndependentlyFromExplicitConfiguration() {
        for (String property : new String[]{"creator-rewards", "seckill", "group-buy"}) {
            new ApplicationContextRunner().withUserConfiguration(Config.class)
                    .withPropertyValues("app.launch.eu." + property + "-enabled=true")
                    .run(context -> {
                        var eu = context.getBean(LaunchPolicy.class).capabilities(Region.EU);
                        assertThat(eu.creatorRewards()).isEqualTo(property.equals("creator-rewards"));
                        assertThat(eu.seckill()).isEqualTo(property.equals("seckill"));
                        assertThat(eu.groupBuy()).isEqualTo(property.equals("group-buy"));
                    });
        }
    }
}
