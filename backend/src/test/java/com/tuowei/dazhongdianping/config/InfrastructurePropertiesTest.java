package com.tuowei.dazhongdianping.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.bind.Bindable;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.ConfigurationPropertySource;
import org.springframework.boot.context.properties.source.MapConfigurationPropertySource;
import org.springframework.data.redis.core.StringRedisTemplate;

class InfrastructurePropertiesTest {

    @Test
    void shouldBindRedisStateStoreProperties() {
        ConfigurationPropertySource source = new MapConfigurationPropertySource(
                java.util.Map.of(
                        "app.infrastructure.state-store.provider", "redis",
                        "app.infrastructure.state-store.key-prefix", "dzdp:test"
                )
        );

        InfrastructureProperties properties = new Binder(source)
                .bind("app.infrastructure", Bindable.of(InfrastructureProperties.class))
                .get();

        assertThat(properties.getStateStore().getProvider()).isEqualTo(InfrastructureProperties.StateStoreProvider.REDIS);
        assertThat(properties.getStateStore().getKeyPrefix()).isEqualTo("dzdp:test");
    }

    @Test
    void shouldHaveRedisTemplateTypeAvailableForRedisStateStore() {
        assertThat(StringRedisTemplate.class.getName()).isEqualTo("org.springframework.data.redis.core.StringRedisTemplate");
    }
}
