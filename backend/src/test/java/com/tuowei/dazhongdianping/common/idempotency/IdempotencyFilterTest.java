package com.tuowei.dazhongdianping.common.idempotency;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
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
