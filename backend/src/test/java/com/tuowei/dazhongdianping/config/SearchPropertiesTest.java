package com.tuowei.dazhongdianping.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.bind.Bindable;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.ConfigurationPropertySource;
import org.springframework.boot.context.properties.source.MapConfigurationPropertySource;

class SearchPropertiesTest {

    @Test
    void shouldBindManagedOpenSearchAuthenticationProperties() {
        ConfigurationPropertySource source = new MapConfigurationPropertySource(java.util.Map.of(
                "app.search.provider", "elasticsearch",
                "app.search.base-url", "https://search.example.test",
                "app.search.index-name", "dzdp_shop_eu_test_v1",
                "app.search.username", "search-user",
                "app.search.password", "search-password",
                "app.search.fallback-on-error", "false"
        ));

        SearchProperties properties = new Binder(source)
                .bind("app.search", Bindable.of(SearchProperties.class))
                .get();

        assertThat(properties.getProvider()).isEqualTo(SearchProperties.Provider.ELASTICSEARCH);
        assertThat(properties.getBaseUrl()).isEqualTo("https://search.example.test");
        assertThat(properties.getIndexName()).isEqualTo("dzdp_shop_eu_test_v1");
        assertThat(properties.getUsername()).isEqualTo("search-user");
        assertThat(properties.getPassword()).isEqualTo("search-password");
        assertThat(properties.isFallbackOnError()).isFalse();
    }
}
