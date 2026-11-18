package com.tuowei.dazhongdianping.config;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import software.amazon.awssdk.services.s3.S3Client;

class S3StorageConfigTest {

    private final S3StorageConfig config = new S3StorageConfig();

    @Test
    void shouldAllowDefaultCredentialChainWithoutStaticKeys() {
        FileStorageProperties properties = properties(FileStorageProperties.S3.CredentialsProvider.DEFAULT_CHAIN);

        assertThatCode(() -> {
            try (S3Client ignored = config.s3Client(properties)) {
                // Client construction must not resolve credentials or contact AWS.
            }
        }).doesNotThrowAnyException();
    }

    @Test
    void shouldRejectStaticProviderWithoutBothKeys() {
        FileStorageProperties properties = properties(FileStorageProperties.S3.CredentialsProvider.STATIC);
        properties.getS3().setAccessKey("access-only");

        assertThatThrownBy(() -> config.s3Client(properties))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("APP_S3_ACCESS_KEY")
                .hasMessageContaining("APP_S3_SECRET_KEY");
    }

    @Test
    void shouldRejectStaticKeysWithDefaultCredentialChain() {
        FileStorageProperties properties = properties(FileStorageProperties.S3.CredentialsProvider.DEFAULT_CHAIN);
        properties.getS3().setAccessKey("access");
        properties.getS3().setSecretKey("secret");

        assertThatThrownBy(() -> config.s3Client(properties))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("default_chain");
    }

    private FileStorageProperties properties(FileStorageProperties.S3.CredentialsProvider provider) {
        FileStorageProperties properties = new FileStorageProperties();
        properties.setProvider(FileStorageProperties.Provider.S3);
        properties.getS3().setBucket("dzdp-test");
        properties.getS3().setRegion("eu-west-3");
        properties.getS3().setCredentialsProvider(provider);
        return properties;
    }
}
