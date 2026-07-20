package com.tuowei.dazhongdianping.config;

import java.net.URI;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
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
        if (StringUtils.hasText(s3.getAccessKey()) || StringUtils.hasText(s3.getSecretKey())) {
            builder.credentialsProvider(StaticCredentialsProvider.create(
                    AwsBasicCredentials.create(s3.getAccessKey(), s3.getSecretKey())
            ));
        }
        return builder.build();
    }
}
