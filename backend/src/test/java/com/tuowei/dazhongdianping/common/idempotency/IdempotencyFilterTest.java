package com.tuowei.dazhongdianping.common.idempotency;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import jakarta.servlet.FilterChain;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class IdempotencyFilterTest {

    @Test
    void shouldExecuteConcurrentLocalRequestsWithSameKeyOnlyOnce() throws Exception {
        InfrastructureProperties infrastructureProperties = new InfrastructureProperties();
        IdempotencyFilter filter = new IdempotencyFilter(
                new ObjectMapper(),
                infrastructureProperties,
                providerOf(null)
        );

        AtomicInteger chainInvocations = new AtomicInteger();
        CountDownLatch firstEnteredChain = new CountDownLatch(1);
        CountDownLatch releaseChain = new CountDownLatch(1);
        FilterChain chain = (servletRequest, servletResponse) -> {
            chainInvocations.incrementAndGet();
            firstEnteredChain.countDown();
            try {
                if (!releaseChain.await(5, TimeUnit.SECONDS)) {
                    throw new IllegalStateException("timed out waiting to release test chain");
                }
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(exception);
            }
            servletResponse.setContentType(MediaType.APPLICATION_JSON_VALUE);
            servletResponse.getOutputStream().write("{\"code\":0,\"data\":{\"id\":101}}".getBytes(StandardCharsets.UTF_8));
        };

        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Future<MockHttpServletResponse> first = executor.submit(() -> invoke(filter, localRequest("{\"content\":\"same\"}"), chain));
            assertThat(firstEnteredChain.await(5, TimeUnit.SECONDS)).isTrue();
            Future<MockHttpServletResponse> second = executor.submit(() -> invoke(filter, localRequest("{\"content\":\"same\"}"), chain));

            Thread.sleep(100);
            releaseChain.countDown();

            MockHttpServletResponse firstResponse = first.get(5, TimeUnit.SECONDS);
            MockHttpServletResponse secondResponse = second.get(5, TimeUnit.SECONDS);
            assertThat(chainInvocations).hasValue(1);
            assertThat(firstResponse.getContentAsString()).isEqualTo(secondResponse.getContentAsString());
            assertThat(secondResponse.getContentAsString()).contains("\"id\":101");
        } finally {
            releaseChain.countDown();
            executor.shutdownNow();
        }
    }

    @Test
    void shouldStoreSuccessfulResponseInRedisWhenStateStoreProviderIsRedis() throws Exception {
        InfrastructureProperties infrastructureProperties = new InfrastructureProperties();
        infrastructureProperties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        infrastructureProperties.getStateStore().setKeyPrefix("dzdp:test");

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get(anyString())).thenReturn(null);
        when(valueOperations.setIfAbsent(anyString(), anyString(), any(java.time.Duration.class))).thenReturn(true);

        IdempotencyFilter filter = new IdempotencyFilter(
                new ObjectMapper(),
                infrastructureProperties,
                providerOf(redisTemplate)
        );

        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/c/v1/reviews");
        request.setContentType(MediaType.APPLICATION_JSON_VALUE);
        request.addHeader(IdempotencyFilter.IDEMPOTENCY_KEY_HEADER, "idem-key-1234567890");
        request.setContent("{\"content\":\"first\"}".getBytes(StandardCharsets.UTF_8));

        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (servletRequest, servletResponse) -> {
            servletResponse.setContentType(MediaType.APPLICATION_JSON_VALUE);
            servletResponse.getOutputStream().write("{\"code\":0}".getBytes(StandardCharsets.UTF_8));
        };

        filter.doFilter(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(200);
        verify(valueOperations).set(anyString(), anyString(), any(java.time.Duration.class));
    }

    @Test
    void shouldReplayStoredRedisResponseForSameIdempotencyKeyAndBody() throws Exception {
        InfrastructureProperties infrastructureProperties = new InfrastructureProperties();
        infrastructureProperties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        infrastructureProperties.getStateStore().setKeyPrefix("dzdp:test");

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
        AtomicReference<String> storedJson = new AtomicReference<>();
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get(anyString())).thenAnswer(ignored -> storedJson.get());
        when(valueOperations.setIfAbsent(anyString(), anyString(), any(java.time.Duration.class))).thenAnswer(invocation ->
                storedJson.compareAndSet(null, invocation.getArgument(1, String.class))
        );
        org.mockito.Mockito.doAnswer(invocation -> {
            storedJson.set(invocation.getArgument(1, String.class));
            return null;
        }).when(valueOperations).set(anyString(), anyString(), any(java.time.Duration.class));

        IdempotencyFilter filter = new IdempotencyFilter(
                new ObjectMapper(),
                infrastructureProperties,
                providerOf(redisTemplate)
        );

        FilterChain chain = (servletRequest, servletResponse) -> {
            servletResponse.setContentType(MediaType.APPLICATION_JSON_VALUE);
            servletResponse.getOutputStream().write("{\"code\":0,\"data\":{\"token\":\"first-token\"}}".getBytes(StandardCharsets.UTF_8));
        };

        MockHttpServletResponse firstResponse = new MockHttpServletResponse();
        filter.doFilter(redisRequest(), firstResponse, chain);

        MockHttpServletResponse replayResponse = new MockHttpServletResponse();
        filter.doFilter(redisRequest(), replayResponse, (servletRequest, servletResponse) -> {
            throw new AssertionError("idempotency replay must not call the downstream chain");
        });

        assertThat(replayResponse.getStatus()).isEqualTo(200);
        assertThat(replayResponse.getContentAsString()).contains("first-token");
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "not-json-at-all::corrupt", "", " ", "null", "{}", "[]",
            "{\"state\":\"COMPLETED\"}", "{\"state\":\"PROCESSING\"}",
            "{\"state\":\"UNKNOWN\",\"bodyHash\":\"same\"}",
            "{\"state\":null,\"bodyHash\":\"same\",\"expiresAtEpochMillis\":1}"
    })
    void shouldFailClosedWhenRedisRecordIsCorruptInsteadOfReexecuting(String storedValue) throws Exception {
        InfrastructureProperties infrastructureProperties = new InfrastructureProperties();
        infrastructureProperties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        infrastructureProperties.getStateStore().setKeyPrefix("dzdp:test");

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        // 记录存在但既非当前格式也非历史格式 —— 模拟序列化结构变更/值损坏
        when(valueOperations.get(anyString())).thenReturn(storedValue);

        IdempotencyFilter filter = new IdempotencyFilter(
                new ObjectMapper(),
                infrastructureProperties,
                providerOf(redisTemplate)
        );

        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(redisRequest(), response, (servletRequest, servletResponse) -> {
            throw new AssertionError("corrupt idempotency record must not re-execute the downstream chain");
        });

        assertThat(response.getStatus()).isEqualTo(409);
        assertThat(response.getContentAsString()).contains("common.idempotency_unreadable");
        // fail-closed：不能删除损坏记录(否则一删即在下次请求重放写操作)
        verify(redisTemplate, org.mockito.Mockito.never()).delete(anyString());
    }

    @ParameterizedTest
    @ValueSource(booleans = {true, false})
    void shouldReplayLegacyResponseWithStrictAndSpringJacksonSettings(boolean failOnUnknown) throws Exception {
        InfrastructureProperties properties = new InfrastructureProperties();
        properties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        ObjectMapper mapper = new ObjectMapper()
                .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, failOnUnknown);
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> values = mock(ValueOperations.class);
        AtomicReference<String> storedJson = new AtomicReference<>();
        when(redis.opsForValue()).thenReturn(values);
        when(values.get(anyString())).thenAnswer(ignored -> storedJson.get());
        when(values.setIfAbsent(anyString(), anyString(), any(java.time.Duration.class)))
                .thenAnswer(invocation -> storedJson.compareAndSet(null, invocation.getArgument(1, String.class)));
        org.mockito.Mockito.doAnswer(invocation -> {
            storedJson.set(invocation.getArgument(1, String.class));
            return null;
        }).when(values).set(anyString(), anyString(), any(java.time.Duration.class));
        IdempotencyFilter filter = new IdempotencyFilter(mapper, properties, providerOf(redis));
        MockHttpServletResponse first = new MockHttpServletResponse();
        filter.doFilter(redisRequest(), first, (request, response) -> {
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getOutputStream().write("{\"orderId\":123}".getBytes(StandardCharsets.UTF_8));
        });

        storedJson.set(mapper.readTree(storedJson.get()).get("response").toString());
        MockHttpServletResponse replay = new MockHttpServletResponse();
        filter.doFilter(redisRequest(), replay, (request, response) -> {
            throw new AssertionError("legacy response must be replayed without creating another order");
        });
        assertThat(replay.getStatus()).isEqualTo(200);
        assertThat(replay.getContentAsString()).isEqualTo(first.getContentAsString());
    }

    @Test
    void shouldRetainClaimIfResponseCachingFailsAfterBusinessOperation() throws Exception {
        InfrastructureProperties properties = new InfrastructureProperties();
        properties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> values = mock(ValueOperations.class);
        when(redis.opsForValue()).thenReturn(values);
        when(values.setIfAbsent(anyString(), anyString(), any(java.time.Duration.class))).thenReturn(true);
        doThrow(new IllegalStateException("response cache unavailable"))
                .when(values).set(anyString(), anyString(), any(java.time.Duration.class));
        IdempotencyFilter filter = new IdempotencyFilter(new ObjectMapper(), properties, providerOf(redis));
        AtomicInteger businessOperations = new AtomicInteger();

        assertThatThrownBy(() -> filter.doFilter(redisRequest(), new MockHttpServletResponse(),
                (request, response) -> businessOperations.incrementAndGet()))
                .isInstanceOf(IllegalStateException.class).hasMessage("response cache unavailable");
        assertThat(businessOperations).hasValue(1);
        verify(redis, never()).delete(anyString());
    }

    @Test
    void shouldRejectWritesIfConfiguredRedisClientIsMissing() throws Exception {
        InfrastructureProperties properties = new InfrastructureProperties();
        properties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        IdempotencyFilter filter = new IdempotencyFilter(new ObjectMapper(), properties, providerOf(null));
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(redisRequest(), response, (request, ignored) -> {
            throw new AssertionError("configured Redis must not silently fall back to a per-instance cache");
        });
        assertThat(response.getStatus()).isEqualTo(503);
        assertThat(response.getContentAsString()).contains("common.service_unavailable");
    }

    @Test
    void shouldExecuteConcurrentRedisRequestsAcrossFilterInstancesOnlyOnce() throws Exception {
        InfrastructureProperties infrastructureProperties = new InfrastructureProperties();
        infrastructureProperties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        infrastructureProperties.getStateStore().setKeyPrefix("dzdp:test");

        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        @SuppressWarnings("unchecked")
        ValueOperations<String, String> valueOperations = mock(ValueOperations.class);
        AtomicReference<String> storedJson = new AtomicReference<>();
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get(anyString())).thenAnswer(ignored -> storedJson.get());
        when(valueOperations.setIfAbsent(anyString(), anyString(), any(java.time.Duration.class))).thenAnswer(invocation ->
                storedJson.compareAndSet(null, invocation.getArgument(1, String.class))
        );
        org.mockito.Mockito.doAnswer(invocation -> {
            storedJson.set(invocation.getArgument(1, String.class));
            return null;
        }).when(valueOperations).set(anyString(), anyString(), any(java.time.Duration.class));

        IdempotencyFilter firstFilter = new IdempotencyFilter(new ObjectMapper(), infrastructureProperties, providerOf(redisTemplate));
        IdempotencyFilter secondFilter = new IdempotencyFilter(new ObjectMapper(), infrastructureProperties, providerOf(redisTemplate));
        AtomicInteger chainInvocations = new AtomicInteger();
        CountDownLatch firstEnteredChain = new CountDownLatch(1);
        CountDownLatch releaseChain = new CountDownLatch(1);
        FilterChain chain = (servletRequest, servletResponse) -> {
            chainInvocations.incrementAndGet();
            firstEnteredChain.countDown();
            try {
                if (!releaseChain.await(5, TimeUnit.SECONDS)) {
                    throw new IllegalStateException("timed out waiting to release Redis test chain");
                }
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(exception);
            }
            servletResponse.setContentType(MediaType.APPLICATION_JSON_VALUE);
            servletResponse.getOutputStream().write("{\"code\":0,\"data\":{\"id\":202}}".getBytes(StandardCharsets.UTF_8));
        };

        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Future<MockHttpServletResponse> first = executor.submit(() -> invoke(firstFilter, redisRequest(), chain));
            assertThat(firstEnteredChain.await(5, TimeUnit.SECONDS)).isTrue();
            Future<MockHttpServletResponse> second = executor.submit(() -> invoke(secondFilter, redisRequest(), chain));

            Thread.sleep(100);
            releaseChain.countDown();

            MockHttpServletResponse firstResponse = first.get(5, TimeUnit.SECONDS);
            MockHttpServletResponse secondResponse = second.get(5, TimeUnit.SECONDS);
            assertThat(chainInvocations).hasValue(1);
            assertThat(firstResponse.getContentAsString()).isEqualTo(secondResponse.getContentAsString());
            assertThat(secondResponse.getContentAsString()).contains("\"id\":202");
        } finally {
            releaseChain.countDown();
            executor.shutdownNow();
        }
    }

    private MockHttpServletRequest redisRequest() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/c/v1/reviews");
        request.setContentType(MediaType.APPLICATION_JSON_VALUE);
        request.addHeader(IdempotencyFilter.IDEMPOTENCY_KEY_HEADER, "idem-key-1234567890");
        request.setContent("{\"content\":\"first\"}".getBytes(StandardCharsets.UTF_8));
        return request;
    }

    private MockHttpServletRequest localRequest(String body) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/c/v1/reviews");
        request.setContentType(MediaType.APPLICATION_JSON_VALUE);
        request.addHeader(IdempotencyFilter.IDEMPOTENCY_KEY_HEADER, "idem-local-1234567890");
        request.setContent(body.getBytes(StandardCharsets.UTF_8));
        return request;
    }

    private MockHttpServletResponse invoke(IdempotencyFilter filter,
                                           MockHttpServletRequest request,
                                           FilterChain chain) throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, chain);
        return response;
    }

    private ObjectProvider<StringRedisTemplate> providerOf(StringRedisTemplate redisTemplate) {
        return new ObjectProvider<>() {
            @Override
            public StringRedisTemplate getObject(Object... args) {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getIfAvailable() {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getIfUnique() {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getObject() {
                return redisTemplate;
            }
        };
    }
}
