package com.tuowei.dazhongdianping.module.admin.health;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.config.FileStorageProperties;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import com.tuowei.dazhongdianping.config.PushProperties;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import com.tuowei.dazhongdianping.module.admin.health.model.response.AdminSystemHealthComponentResponse;
import com.tuowei.dazhongdianping.module.admin.health.model.response.AdminSystemHealthResponse;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.CannotGetJdbcConnectionException;
import org.springframework.jdbc.core.JdbcTemplate;
import software.amazon.awssdk.services.s3.S3Client;

class AdminSystemHealthServiceTest {

    @TempDir
    private Path tempDir;

    @Test
    void shouldReportConfiguredComponentsAndNormalizedRuntimeMetadata() {
        JdbcTemplate jdbcTemplate = healthyDatabase();
        InfrastructureProperties infrastructure = new InfrastructureProperties();
        SearchProperties search = new SearchProperties();
        FileStorageProperties storage = localStorage();
        VerificationCodeProperties verification = configuredVerification();
        PushProperties push = configuredPush();
        Environment environment = environment("test", "eu");
        AdminSystemHealthService service = service(
                jdbcTemplate, infrastructure, search, storage, verification, push,
                null, null, environment, " PRE ", false, true, "sk_test_fake", "whsec_test_fake");

        AdminSystemHealthResponse response = service.inspect();

        assertThat(response.status()).isEqualTo("up");
        assertThat(response.runtimeMode()).isEqualTo("pre");
        assertThat(response.activeProfiles()).containsExactly("eu", "test");
        assertThat(response.checkedAt()).isNotNull();
        assertThat(response.uptimeSeconds()).isNotNegative();
        assertThat(component(response, "database").status()).isEqualTo("up");
        assertThat(component(response, "stateStore").status()).isEqualTo("disabled");
        assertThat(component(response, "search").status()).isEqualTo("up");
        assertThat(component(response, "fileStorage").status()).isEqualTo("up");
        assertThat(component(response, "payment").status()).isEqualTo("up");
        assertThat(component(response, "verificationCode").status()).isEqualTo("up");
        assertThat(component(response, "verificationCode").detail()).contains("Twilio");
        assertThat(component(response, "push").status()).isEqualTo("up");
        assertThat(component(response, "push").detail()).contains("FCM");
    }

    @Test
    void shouldDegradeWithoutThrowingWhenRedisDependencyFails() {
        InfrastructureProperties infrastructure = new InfrastructureProperties();
        infrastructure.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        RedisConnectionFactory connectionFactory = mock(RedisConnectionFactory.class);
        when(redisTemplate.getConnectionFactory()).thenReturn(connectionFactory);
        when(connectionFactory.getConnection())
                .thenThrow(new RedisConnectionFailureException("redis unavailable"));
        AdminSystemHealthService service = service(
                healthyDatabase(), infrastructure, new SearchProperties(), localStorage(),
                configuredVerification(), configuredPush(), redisTemplate, null,
                environment("test"), "prod", false, true, "sk_test_fake", "whsec_test_fake");

        AdminSystemHealthResponse response = service.inspect();

        assertThat(response.status()).isEqualTo("degraded");
        AdminSystemHealthComponentResponse stateStore = component(response, "stateStore");
        assertThat(stateStore.status()).isEqualTo("down");
        assertThat(stateStore.critical()).isFalse();
        assertThat(stateStore.detail()).isEqualTo("Redis 状态存储连接失败");
        assertThat(component(response, "database").status()).isEqualTo("up");
    }

    @Test
    void shouldMarkOverallDownWhenCriticalDatabaseCheckFails() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        when(jdbcTemplate.queryForObject("SELECT 1", Integer.class))
                .thenThrow(new CannotGetJdbcConnectionException("database unavailable"));
        AdminSystemHealthService service = service(
                jdbcTemplate, new InfrastructureProperties(), new SearchProperties(), localStorage(),
                configuredVerification(), configuredPush(), null, null,
                environment("test"), "prod", false, true, "sk_test_fake", "whsec_test_fake");

        AdminSystemHealthResponse response = service.inspect();

        assertThat(response.status()).isEqualTo("down");
        AdminSystemHealthComponentResponse database = component(response, "database");
        assertThat(database.status()).isEqualTo("down");
        assertThat(database.critical()).isTrue();
        assertThat(database.detail()).isEqualTo("数据库连接不可用");
    }

    private JdbcTemplate healthyDatabase() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        when(jdbcTemplate.queryForObject("SELECT 1", Integer.class)).thenReturn(1);
        return jdbcTemplate;
    }

    private FileStorageProperties localStorage() {
        FileStorageProperties properties = new FileStorageProperties();
        properties.setProvider(FileStorageProperties.Provider.LOCAL);
        properties.setBaseDir(tempDir.toString());
        return properties;
    }

    private VerificationCodeProperties configuredVerification() {
        VerificationCodeProperties properties = new VerificationCodeProperties();
        properties.getTwilio().setEnabled(true);
        properties.getTwilio().setAccountSid("AC_test_account");
        properties.getTwilio().setAuthToken("test-token");
        properties.getTwilio().setMessagingServiceSid("MG_test_service");
        return properties;
    }

    private PushProperties configuredPush() {
        PushProperties properties = new PushProperties();
        properties.setEnabled(true);
        properties.getFcm().setProjectId("test-project");
        properties.getFcm().setClientEmail("push@test.example");
        properties.getFcm().setPrivateKey("test-private-key");
        return properties;
    }

    private Environment environment(String... activeProfiles) {
        Environment environment = mock(Environment.class);
        when(environment.getActiveProfiles()).thenReturn(activeProfiles);
        return environment;
    }

    private AdminSystemHealthService service(
            JdbcTemplate jdbcTemplate,
            InfrastructureProperties infrastructure,
            SearchProperties search,
            FileStorageProperties storage,
            VerificationCodeProperties verification,
            PushProperties push,
            StringRedisTemplate redisTemplate,
            S3Client s3Client,
            Environment environment,
            String runtimeMode,
            boolean paymentMockEnabled,
            boolean stripeEnabled,
            String stripeSecret,
            String stripeEndpointSecret) {
        return new AdminSystemHealthService(
                jdbcTemplate,
                infrastructure,
                search,
                storage,
                verification,
                push,
                provider(redisTemplate),
                provider(s3Client),
                environment,
                runtimeMode,
                paymentMockEnabled,
                stripeEnabled,
                stripeSecret,
                stripeEndpointSecret
        );
    }

    @SuppressWarnings("unchecked")
    private <T> ObjectProvider<T> provider(T value) {
        ObjectProvider<T> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(value);
        return provider;
    }

    private AdminSystemHealthComponentResponse component(
            AdminSystemHealthResponse response,
            String key) {
        return response.components().stream()
                .filter(component -> key.equals(component.key()))
                .findFirst()
                .orElseThrow();
    }
}
