package com.tuowei.dazhongdianping.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.bind.Bindable;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.context.properties.source.ConfigurationPropertySource;
import org.springframework.boot.context.properties.source.MapConfigurationPropertySource;

class FileStoragePropertiesTest {

    @Test
    void shouldBindS3CompatibleObjectStorageProperties() {
        ConfigurationPropertySource source = new MapConfigurationPropertySource(
                java.util.Map.of(
                        "app.file-storage.provider", "s3",
                        "app.file-storage.s3.bucket", "dzdp-test",
                        "app.file-storage.s3.region", "eu-west-1",
                        "app.file-storage.s3.endpoint", "https://s3.example.test",
                        "app.file-storage.s3.public-base-url", "https://cdn.example.test/uploads",
                        "app.file-storage.s3.access-key", "test-access",
                        "app.file-storage.s3.secret-key", "test-secret",
                        "app.file-storage.s3.path-style-access-enabled", "true"
                )
        );

        FileStorageProperties properties = new Binder(source)
                .bind("app.file-storage", Bindable.of(FileStorageProperties.class))
                .get();

        assertThat(properties.getProvider()).isEqualTo(FileStorageProperties.Provider.S3);
        assertThat(properties.getS3().getBucket()).isEqualTo("dzdp-test");
        assertThat(properties.getS3().getRegion()).isEqualTo("eu-west-1");
        assertThat(properties.getS3().getEndpoint()).isEqualTo("https://s3.example.test");
        assertThat(properties.getS3().getPublicBaseUrl()).isEqualTo("https://cdn.example.test/uploads");
        assertThat(properties.getS3().getAccessKey()).isEqualTo("test-access");
        assertThat(properties.getS3().getSecretKey()).isEqualTo("test-secret");
        assertThat(properties.getS3().isPathStyleAccessEnabled()).isTrue();
    }
}
