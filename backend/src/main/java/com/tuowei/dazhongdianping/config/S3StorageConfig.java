package com.tuowei.dazhongdianping.config;

import java.net.URI;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;
import software.amazon.awssdk.services.s3.S3Configuration;

@Configuration
@ConditionalOnProperty(prefix = "app.file-storage", name = "provider", havingValue = "s3")
public class S3StorageConfig {

    @Bean
    public S3Client s3Client(FileStorageProperties properties) {
        FileStorageProperties.S3 s3 = properties.getS3();
        S3ClientBuilder builder = S3Client.builder()
                .region(Region.of(s3.getRegion()))
                .serviceConfiguration(S3Configuration.builder()
                        .pathStyleAccessEnabled(s3.isPathStyleAccessEnabled())
                        .build());

        if (StringUtils.hasText(s3.getEndpoint())) {
            builder.endpointOverride(URI.create(s3.getEndpoint()));
        }
        boolean hasAccessKey = StringUtils.hasText(s3.getAccessKey());
        boolean hasSecretKey = StringUtils.hasText(s3.getSecretKey());
        switch (s3.getCredentialsProvider()) {
            case STATIC -> builder.credentialsProvider(staticCredentials(s3, hasAccessKey, hasSecretKey));
            case DEFAULT_CHAIN -> {
                if (hasAccessKey || hasSecretKey) {
                    throw new IllegalStateException(
                            "APP_S3_CREDENTIALS_PROVIDER=default_chain cannot be combined with static S3 keys");
                }
                builder.credentialsProvider(DefaultCredentialsProvider.create());
            }
            case AUTO -> {
                if (hasAccessKey || hasSecretKey) {
                    builder.credentialsProvider(staticCredentials(s3, hasAccessKey, hasSecretKey));
                }
            }
        }
        return builder.build();
    }

    private StaticCredentialsProvider staticCredentials(
            FileStorageProperties.S3 s3,
            boolean hasAccessKey,
            boolean hasSecretKey) {
        if (!hasAccessKey || !hasSecretKey) {
            throw new IllegalStateException(
                    "static S3 credentials require both APP_S3_ACCESS_KEY and APP_S3_SECRET_KEY");
        }
        return StaticCredentialsProvider.create(
                AwsBasicCredentials.create(s3.getAccessKey(), s3.getSecretKey()));
    }
}
