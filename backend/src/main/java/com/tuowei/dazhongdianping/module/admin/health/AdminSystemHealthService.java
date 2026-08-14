package com.tuowei.dazhongdianping.module.admin.health;

import com.tuowei.dazhongdianping.config.FileStorageProperties;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import com.tuowei.dazhongdianping.config.PushProperties;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import com.tuowei.dazhongdianping.module.admin.health.model.response.AdminSystemHealthComponentResponse;
import com.tuowei.dazhongdianping.module.admin.health.model.response.AdminSystemHealthResponse;
import java.lang.management.ManagementFactory;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;

@Service
public class AdminSystemHealthService {

    private static final Duration EXTERNAL_CONNECT_TIMEOUT = Duration.ofSeconds(2);
    private static final Duration EXTERNAL_REQUEST_TIMEOUT = Duration.ofSeconds(3);

    private final JdbcTemplate jdbcTemplate;
    private final InfrastructureProperties infrastructureProperties;
    private final SearchProperties searchProperties;
    private final FileStorageProperties fileStorageProperties;
    private final VerificationCodeProperties verificationCodeProperties;
    private final PushProperties pushProperties;
    private final StringRedisTemplate redisTemplate;
    private final S3Client s3Client;
    private final Environment environment;
    private final String runtimeMode;
    private final boolean paymentMockEnabled;
    private final boolean stripeEnabled;
    private final boolean stripeSecretConfigured;
    private final boolean stripeEndpointSecretConfigured;
    private final HttpClient httpClient;

    public AdminSystemHealthService(
            JdbcTemplate jdbcTemplate,
            InfrastructureProperties infrastructureProperties,
            SearchProperties searchProperties,
            FileStorageProperties fileStorageProperties,
            VerificationCodeProperties verificationCodeProperties,
            PushProperties pushProperties,
            ObjectProvider<StringRedisTemplate> redisTemplateProvider,
            ObjectProvider<S3Client> s3ClientProvider,
            Environment environment,
            @Value("${app.runtime-mode:prod}") String runtimeMode,
            @Value("${app.payment.mock-enabled:false}") boolean paymentMockEnabled,
            @Value("${app.payment.stripe.enabled:false}") boolean stripeEnabled,
            @Value("${app.payment.stripe.secret-key:}") String stripeSecret,
            @Value("${app.payment.stripe.endpoint-secret:}") String stripeEndpointSecret) {
        this.jdbcTemplate = jdbcTemplate;
        this.infrastructureProperties = infrastructureProperties;
        this.searchProperties = searchProperties;
        this.fileStorageProperties = fileStorageProperties;
        this.verificationCodeProperties = verificationCodeProperties;
        this.pushProperties = pushProperties;
        this.redisTemplate = redisTemplateProvider.getIfAvailable();
        this.s3Client = s3ClientProvider.getIfAvailable();
        this.environment = environment;
        this.runtimeMode = normalizeRuntimeMode(runtimeMode);
        this.paymentMockEnabled = paymentMockEnabled;
        this.stripeEnabled = stripeEnabled;
        this.stripeSecretConfigured = StringUtils.hasText(stripeSecret);
        this.stripeEndpointSecretConfigured = StringUtils.hasText(stripeEndpointSecret);
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(EXTERNAL_CONNECT_TIMEOUT)
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
    }

    public AdminSystemHealthResponse inspect() {
        List<AdminSystemHealthComponentResponse> components = new ArrayList<>();
        components.add(checkDatabase());
        components.add(checkStateStore());
        components.add(checkSearch());
        components.add(checkFileStorage());
        components.add(checkPayment());
        components.add(checkVerificationCode());
        components.add(checkPush());

        return new AdminSystemHealthResponse(
                overallStatus(components),
                LocalDateTime.now(),
                Math.max(0L, ManagementFactory.getRuntimeMXBean().getUptime() / 1000L),
                runtimeMode,
                Optional.ofNullable(getClass().getPackage().getImplementationVersion()).orElse("dev"),
                Arrays.stream(environment.getActiveProfiles()).sorted().toList(),
                List.copyOf(components)
        );
    }

    private AdminSystemHealthComponentResponse checkDatabase() {
        long startedAt = System.nanoTime();
        try {
            Integer value = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            if (!Integer.valueOf(1).equals(value)) {
                return component("database", "down", "connectivity", true, startedAt, "数据库校验结果异常");
            }
            return component("database", "up", "connectivity", true, startedAt, "数据库连接正常");
        } catch (RuntimeException exception) {
            return component("database", "down", "connectivity", true, startedAt, "数据库连接不可用");
        }
    }

    private AdminSystemHealthComponentResponse checkStateStore() {
        if (infrastructureProperties.getStateStore().getProvider()
                != InfrastructureProperties.StateStoreProvider.REDIS) {
            return component("stateStore", "disabled", "provider", false, 0L, "当前使用进程内状态存储");
        }

        long startedAt = System.nanoTime();
        if (redisTemplate == null) {
            return component("stateStore", "down", "connectivity", false, startedAt, "Redis 客户端不可用");
        }
        RedisConnectionFactory connectionFactory = redisTemplate.getConnectionFactory();
        if (connectionFactory == null) {
            return component("stateStore", "down", "connectivity", false, startedAt, "Redis 连接工厂不可用");
        }
        try (RedisConnection connection = connectionFactory.getConnection()) {
            String pong = connection.ping();
            if (!StringUtils.hasText(pong)) {
                return component("stateStore", "down", "connectivity", false, startedAt, "Redis PING 未返回结果");
            }
            return component("stateStore", "up", "connectivity", false, startedAt, "Redis 状态存储连接正常");
        } catch (RuntimeException exception) {
            return component("stateStore", "down", "connectivity", false, startedAt, "Redis 状态存储连接失败");
        }
    }

    private AdminSystemHealthComponentResponse checkSearch() {
        if (searchProperties.getProvider() != SearchProperties.Provider.ELASTICSEARCH) {
            return component("search", "up", "provider", false, 0L, "当前由 MySQL 提供搜索，Elasticsearch 未启用");
        }

        long startedAt = System.nanoTime();
        try {
            URI endpoint = URI.create(trimTrailingSlash(searchProperties.getBaseUrl()) + "/");
            HttpRequest request = HttpRequest.newBuilder(endpoint)
                    .timeout(EXTERNAL_REQUEST_TIMEOUT)
                    .GET()
                    .build();
            HttpResponse<Void> response = httpClient.send(request, HttpResponse.BodyHandlers.discarding());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                return component(
                        "search", "down", "connectivity", false, startedAt,
                        "Elasticsearch 返回 HTTP " + response.statusCode());
            }
            return component("search", "up", "connectivity", false, startedAt, "Elasticsearch 连接正常");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return component("search", "down", "connectivity", false, startedAt, "Elasticsearch 检查已中断");
        } catch (Exception exception) {
            return component("search", "down", "connectivity", false, startedAt, "Elasticsearch 连接失败");
        }
    }

    private AdminSystemHealthComponentResponse checkFileStorage() {
        if (fileStorageProperties.getProvider() == FileStorageProperties.Provider.S3) {
            return checkS3Storage();
        }

        long startedAt = System.nanoTime();
        try {
            Path target = Path.of(fileStorageProperties.getBaseDir()).toAbsolutePath().normalize();
            if (Files.exists(target) && (!Files.isDirectory(target) || !Files.isWritable(target))) {
                return component("fileStorage", "down", "filesystem", false, startedAt, "本地上传目录不可写");
            }
            Path writableParent = nearestExistingPath(target);
            if (writableParent == null || !Files.isDirectory(writableParent) || !Files.isWritable(writableParent)) {
                return component("fileStorage", "down", "filesystem", false, startedAt, "本地上传目录无法创建");
            }
            String detail = Files.exists(target) ? "本地上传目录可写" : "本地上传目录可在首次上传时创建";
            return component("fileStorage", "up", "filesystem", false, startedAt, detail);
        } catch (RuntimeException exception) {
            return component("fileStorage", "down", "filesystem", false, startedAt, "本地上传目录配置无效");
        }
    }

    private AdminSystemHealthComponentResponse checkS3Storage() {
        long startedAt = System.nanoTime();
        String bucket = fileStorageProperties.getS3().getBucket();
        if (!StringUtils.hasText(bucket) || s3Client == null) {
            return component("fileStorage", "down", "connectivity", false, startedAt, "S3 客户端或 bucket 未配置");
        }
        try {
            HeadBucketRequest request = HeadBucketRequest.builder()
                    .bucket(bucket.trim())
                    .overrideConfiguration(builder -> builder
                            .apiCallTimeout(EXTERNAL_REQUEST_TIMEOUT)
                            .apiCallAttemptTimeout(EXTERNAL_CONNECT_TIMEOUT))
                    .build();
            s3Client.headBucket(request);
            return component("fileStorage", "up", "connectivity", false, startedAt, "S3 bucket 可访问");
        } catch (RuntimeException exception) {
            return component("fileStorage", "down", "connectivity", false, startedAt, "S3 bucket 访问失败");
        }
    }

    private AdminSystemHealthComponentResponse checkPayment() {
        if (stripeEnabled) {
            if (stripeSecretConfigured && stripeEndpointSecretConfigured) {
                return component("payment", "up", "configuration", false, 0L, "Stripe 支付与回调配置已就绪");
            }
            return component("payment", "warning", "configuration", false, 0L, "Stripe 已启用但凭证配置不完整");
        }
        if (paymentMockEnabled) {
            return component("payment", "warning", "configuration", false, 0L, "当前使用模拟支付渠道");
        }
        return component("payment", "disabled", "configuration", false, 0L, "未启用支付渠道");
    }

    private AdminSystemHealthComponentResponse checkVerificationCode() {
        List<String> channels = new ArrayList<>();
        if (verificationCodeProperties.getMail().isConfigured()) {
            channels.add("邮件");
        }
        if (verificationCodeProperties.getAliyun().isConfigured()) {
            channels.add("阿里云短信");
        }
        if (verificationCodeProperties.getTwilio().isConfigured()) {
            channels.add("Twilio");
        }
        if (!channels.isEmpty()) {
            return component(
                    "verificationCode", "up", "configuration", false, 0L,
                    "已配置验证码渠道：" + String.join("、", channels));
        }
        if (verificationCodeProperties.isMockEnabled() || verificationCodeProperties.isDevConsoleEnabled()) {
            return component("verificationCode", "warning", "configuration", false, 0L, "当前使用开发验证码渠道");
        }
        return component("verificationCode", "warning", "configuration", false, 0L, "未配置可用验证码渠道");
    }

    private AdminSystemHealthComponentResponse checkPush() {
        if (!pushProperties.isEnabled()) {
            return component("push", "disabled", "configuration", false, 0L, "推送功能未启用");
        }
        List<String> channels = new ArrayList<>();
        if (pushProperties.getFcm().isConfigured()) {
            channels.add("FCM");
        }
        if (pushProperties.getApns().isConfigured()) {
            channels.add("APNs");
        }
        if (channels.isEmpty()) {
            return component("push", "warning", "configuration", false, 0L, "推送已启用但没有完整渠道配置");
        }
        return component("push", "up", "configuration", false, 0L, "已配置推送渠道：" + String.join("、", channels));
    }

    private String overallStatus(List<AdminSystemHealthComponentResponse> components) {
        boolean criticalDown = components.stream()
                .anyMatch(component -> component.critical() && "down".equals(component.status()));
        if (criticalDown) {
            return "down";
        }
        boolean degraded = components.stream()
                .anyMatch(component -> "down".equals(component.status()) || "warning".equals(component.status()));
        return degraded ? "degraded" : "up";
    }

    private AdminSystemHealthComponentResponse component(String key,
                                                          String status,
                                                          String checkType,
                                                          boolean critical,
                                                          long startedAt,
                                                          String detail) {
        long latencyMillis = startedAt <= 0L
                ? 0L
                : Math.max(0L, (System.nanoTime() - startedAt) / 1_000_000L);
        return new AdminSystemHealthComponentResponse(
                key, status, checkType, critical, latencyMillis, detail);
    }

    private Path nearestExistingPath(Path path) {
        Path cursor = path;
        while (cursor != null && !Files.exists(cursor)) {
            cursor = cursor.getParent();
        }
        return cursor;
    }

    private String trimTrailingSlash(String value) {
        String normalized = StringUtils.hasText(value) ? value.trim() : "http://127.0.0.1:9200";
        while (normalized.endsWith("/")) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }
        return normalized;
    }

    private String normalizeRuntimeMode(String value) {
        return StringUtils.hasText(value) ? value.trim().toLowerCase(Locale.ROOT) : "prod";
    }
}
