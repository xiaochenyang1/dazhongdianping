package com.tuowei.dazhongdianping.common.idempotency;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingResponseWrapper;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 20)
public class IdempotencyFilter extends OncePerRequestFilter {

    public static final String IDEMPOTENCY_KEY_HEADER = "Idempotency-Key";

    private static final Set<String> MUTATING_METHODS = Set.of("POST", "PUT", "DELETE");
    private static final int MIN_KEY_LENGTH = 16;
    private static final int MAX_KEY_LENGTH = 64;
    private static final int CLEANUP_INTERVAL = 128;
    private static final Duration REDIS_PROCESSING_TTL = Duration.ofMinutes(10);
    private static final Duration REDIS_WAIT_TIMEOUT = Duration.ofSeconds(30);

    private final ObjectMapper objectMapper;
    private final InfrastructureProperties infrastructureProperties;
    private final StringRedisTemplate redisTemplate;
    private final ConcurrentMap<String, StoredResponse> responseCache = new ConcurrentHashMap<>();
    private final ConcurrentMap<String, PendingRequest> pendingRequests = new ConcurrentHashMap<>();
    private final AtomicInteger requestCounter = new AtomicInteger();
    private final Duration ttl = Duration.ofHours(24);

    public IdempotencyFilter(ObjectMapper objectMapper,
                             InfrastructureProperties infrastructureProperties,
                             ObjectProvider<StringRedisTemplate> redisTemplateProvider) {
        this.objectMapper = objectMapper;
        this.infrastructureProperties = infrastructureProperties;
        this.redisTemplate = redisTemplateProvider.getIfAvailable();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        if (!shouldHandle(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        String idempotencyKey = request.getHeader(IDEMPOTENCY_KEY_HEADER);
        if (!isValidKey(idempotencyKey)) {
            writeError(response, HttpStatus.BAD_REQUEST, 400, "Idempotency-Key 长度必须在 16 到 64 位之间", "common.bad_request");
            return;
        }

        cleanupExpiredEntries();

        CachedBodyRequest wrappedRequest = new CachedBodyRequest(request);
        String bodyHash = sha256(wrappedRequest.cachedBody());
        String scopeKey = scopeKey(request, idempotencyKey);
        if (!useRedis()) {
            handleLocalRequest(wrappedRequest, response, filterChain, bodyHash, scopeKey);
            return;
        }

        handleRedisRequest(wrappedRequest, response, filterChain, bodyHash, scopeKey);
    }

    private void handleLocalRequest(CachedBodyRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain,
                                    String bodyHash,
                                    String scopeKey) throws IOException, ServletException {
        StoredResponse storedResponse = responseCache.get(scopeKey);
        if (replayIfAvailable(response, storedResponse, bodyHash)) {
            return;
        }

        PendingRequest candidate = new PendingRequest(bodyHash);
        PendingRequest activeRequest = pendingRequests.putIfAbsent(scopeKey, candidate);
        if (activeRequest != null) {
            if (!activeRequest.bodyHash().equals(bodyHash)) {
                writeConflict(response);
                return;
            }
            replayPendingResponse(response, activeRequest);
            return;
        }

        try {
            storedResponse = responseCache.get(scopeKey);
            if (storedResponse != null && !storedResponse.expired(Instant.now())) {
                if (!storedResponse.bodyHash().equals(bodyHash)) {
                    candidate.completeExceptionally(new IllegalStateException("idempotency body hash conflict"));
                    writeConflict(response);
                } else {
                    candidate.complete(storedResponse);
                    replay(response, storedResponse);
                }
                return;
            }

            ContentCachingResponseWrapper wrappedResponse = new ContentCachingResponseWrapper(response);
            filterChain.doFilter(request, wrappedResponse);
            byte[] responseBody = wrappedResponse.getContentAsByteArray();
            StoredResponse completedResponse = StoredResponse.from(
                    wrappedResponse,
                    responseBody,
                    bodyHash,
                    Instant.now().plus(ttl)
            );
            if (wrappedResponse.getStatus() < 500 && responseBody.length > 0) {
                responseCache.put(scopeKey, completedResponse);
            }
            candidate.complete(completedResponse);
            wrappedResponse.copyBodyToResponse();
        } catch (IOException | ServletException | RuntimeException exception) {
            candidate.completeExceptionally(exception);
            throw exception;
        } finally {
            pendingRequests.remove(scopeKey, candidate);
        }
    }

    private boolean replayIfAvailable(HttpServletResponse response,
                                      StoredResponse storedResponse,
                                      String bodyHash) throws IOException {
        if (storedResponse == null || storedResponse.expired(Instant.now())) {
            return false;
        }
        if (!storedResponse.bodyHash().equals(bodyHash)) {
            writeConflict(response);
            return true;
        }
        replay(response, storedResponse);
        return true;
    }

    private void replayPendingResponse(HttpServletResponse response, PendingRequest pendingRequest) throws IOException {
        try {
            replay(response, pendingRequest.await());
        } catch (TimeoutException exception) {
            writeError(response, HttpStatus.CONFLICT, 409, "相同请求正在处理中，请稍后重试", "common.idempotency_in_progress");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            writeError(response, HttpStatus.SERVICE_UNAVAILABLE, 503, "幂等请求等待被中断", "common.service_unavailable");
        } catch (ExecutionException exception) {
            writeError(response, HttpStatus.CONFLICT, 409, "首次请求处理失败，请稍后重试", "common.idempotency_failed");
        }
    }

    private void writeConflict(HttpServletResponse response) throws IOException {
        writeError(response, HttpStatus.CONFLICT, 409, "Idempotency-Key 已被不同请求体使用", "common.idempotency_conflict");
    }

    private void handleRedisRequest(CachedBodyRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain,
                                    String bodyHash,
                                    String scopeKey) throws IOException, ServletException {
        String key = redisKey(scopeKey);
        RedisIdempotencyRecord existing = readRedisRecord(key);
        if (existing != null) {
            replayRedisRecord(response, key, existing, bodyHash);
            return;
        }

        RedisIdempotencyRecord processing = RedisIdempotencyRecord.processing(
                bodyHash,
                UUID.randomUUID().toString(),
                Instant.now().plus(REDIS_PROCESSING_TTL)
        );
        boolean claimed = Boolean.TRUE.equals(redisTemplate.opsForValue().setIfAbsent(
                key,
                objectMapper.writeValueAsString(processing),
                REDIS_PROCESSING_TTL
        ));
        if (!claimed) {
            RedisIdempotencyRecord claimedRecord = readRedisRecord(key);
            if (claimedRecord == null) {
                writeError(response, HttpStatus.CONFLICT, 409, "相同请求正在处理中，请稍后重试", "common.idempotency_in_progress");
                return;
            }
            replayRedisRecord(response, key, claimedRecord, bodyHash);
            return;
        }

        try {
            ContentCachingResponseWrapper wrappedResponse = new ContentCachingResponseWrapper(response);
            filterChain.doFilter(request, wrappedResponse);
            byte[] responseBody = wrappedResponse.getContentAsByteArray();
            StoredResponse completedResponse = StoredResponse.from(
                    wrappedResponse,
                    responseBody,
                    bodyHash,
                    Instant.now().plus(ttl)
            );
            RedisIdempotencyRecord completed = RedisIdempotencyRecord.completed(completedResponse);
            redisTemplate.opsForValue().set(key, objectMapper.writeValueAsString(completed), ttl);
            wrappedResponse.copyBodyToResponse();
        } catch (IOException | ServletException | RuntimeException exception) {
            redisTemplate.delete(key);
            throw exception;
        }
    }

    private RedisIdempotencyRecord readRedisRecord(String key) {
        String json = redisTemplate.opsForValue().get(key);
        if (!StringUtils.hasText(json)) {
            return null;
        }
        try {
            return objectMapper.readValue(json, RedisIdempotencyRecord.class);
        } catch (IOException currentFormatException) {
            try {
                StoredResponse legacyResponse = objectMapper.readValue(json, StoredResponse.class);
                return RedisIdempotencyRecord.completed(legacyResponse);
            } catch (IOException legacyFormatException) {
                redisTemplate.delete(key);
                return null;
            }
        }
    }

    private void replayRedisRecord(HttpServletResponse response,
                                   String key,
                                   RedisIdempotencyRecord record,
                                   String bodyHash) throws IOException {
        if (!record.bodyHash().equals(bodyHash)) {
            writeConflict(response);
            return;
        }
        if (record.completed()) {
            replay(response, record.response());
            return;
        }

        Instant deadline = Instant.now().plus(REDIS_WAIT_TIMEOUT);
        while (Instant.now().isBefore(deadline)) {
            try {
                Thread.sleep(25);
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                writeError(response, HttpStatus.SERVICE_UNAVAILABLE, 503, "幂等请求等待被中断", "common.service_unavailable");
                return;
            }

            RedisIdempotencyRecord current = readRedisRecord(key);
            if (current == null) {
                writeError(response, HttpStatus.CONFLICT, 409, "首次请求处理失败，请稍后重试", "common.idempotency_failed");
                return;
            }
            if (!current.bodyHash().equals(bodyHash)) {
                writeConflict(response);
                return;
            }
            if (current.completed()) {
                replay(response, current.response());
                return;
            }
        }
        writeError(response, HttpStatus.CONFLICT, 409, "相同请求正在处理中，请稍后重试", "common.idempotency_in_progress");
    }

    private boolean useRedis() {
        return infrastructureProperties.getStateStore().getProvider() == InfrastructureProperties.StateStoreProvider.REDIS
                && redisTemplate != null;
    }

    private String redisKey(String scopeKey) {
        String prefix = infrastructureProperties.getStateStore().getKeyPrefix();
        if (!StringUtils.hasText(prefix)) {
            prefix = "dzdp";
        }
        return prefix + ":idempotency:" + scopeKey;
    }

    private boolean shouldHandle(HttpServletRequest request) {
        if (!MUTATING_METHODS.contains(request.getMethod())) {
            return false;
        }
        if (!StringUtils.hasText(request.getHeader(IDEMPOTENCY_KEY_HEADER))) {
            return false;
        }
        String contentType = request.getContentType();
        return contentType == null || contentType.startsWith(MediaType.APPLICATION_JSON_VALUE);
    }

    private boolean isValidKey(String idempotencyKey) {
        return StringUtils.hasText(idempotencyKey)
                && idempotencyKey.length() >= MIN_KEY_LENGTH
                && idempotencyKey.length() <= MAX_KEY_LENGTH;
    }

    private String scopeKey(HttpServletRequest request, String idempotencyKey) {
        String caller = StringUtils.hasText(request.getHeader(HttpHeaders.AUTHORIZATION))
                ? request.getHeader(HttpHeaders.AUTHORIZATION)
                : "anonymous:" + request.getRemoteAddr();
        String query = StringUtils.hasText(request.getQueryString()) ? "?" + request.getQueryString() : "";
        return sha256(caller + "|" + request.getMethod() + "|" + request.getRequestURI() + query + "|" + idempotencyKey);
    }

    private void cleanupExpiredEntries() {
        if (requestCounter.incrementAndGet() % CLEANUP_INTERVAL != 0) {
            return;
        }
        Instant now = Instant.now();
        responseCache.entrySet().removeIf(entry -> entry.getValue().expired(now));
    }

    private void replay(HttpServletResponse response, StoredResponse storedResponse) throws IOException {
        response.setStatus(storedResponse.status());
        response.setCharacterEncoding(storedResponse.characterEncoding());
        if (StringUtils.hasText(storedResponse.contentType())) {
            response.setContentType(storedResponse.contentType());
        }

        storedResponse.headers().forEach((name, values) -> {
            if (!values.isEmpty()) {
                response.setHeader(name, values.get(0));
                values.stream().skip(1).forEach(value -> response.addHeader(name, value));
            }
        });
        response.getOutputStream().write(storedResponse.body());
    }

    private void writeError(HttpServletResponse response,
                            HttpStatus status,
                            int code,
                            String message,
                            String messageKey) throws IOException {
        response.setStatus(status.value());
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), ApiResponse.error(code, message, messageKey));
    }

    private String sha256(String value) {
        return sha256(value.getBytes(StandardCharsets.UTF_8));
    }

    private String sha256(byte[] value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(value));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 not available", exception);
        }
    }

    private record StoredResponse(
            int status,
            String contentType,
            String characterEncoding,
            Map<String, List<String>> headers,
            byte[] body,
            String bodyHash,
            long expiresAtEpochMillis
    ) {
        static StoredResponse from(ContentCachingResponseWrapper response,
                                   byte[] body,
                                   String bodyHash,
                                   Instant expiresAt) {
            return new StoredResponse(
                    response.getStatus(),
                    response.getContentType(),
                    response.getCharacterEncoding(),
                    headers(response.getHeaderNames(), response),
                    body.clone(),
                    bodyHash,
                    expiresAt.toEpochMilli()
            );
        }

        boolean expired(Instant now) {
            return expiresAtEpochMillis <= now.toEpochMilli();
        }

        private static Map<String, List<String>> headers(Collection<String> names, ContentCachingResponseWrapper response) {
            Map<String, List<String>> headers = new ConcurrentHashMap<>();
            for (String name : names) {
                headers.put(name, new ArrayList<>(response.getHeaders(name)));
            }
            return headers;
        }
    }

    private record RedisIdempotencyRecord(
            String state,
            String bodyHash,
            String ownerToken,
            StoredResponse response,
            long expiresAtEpochMillis
    ) {
        private static RedisIdempotencyRecord processing(String bodyHash, String ownerToken, Instant expiresAt) {
            return new RedisIdempotencyRecord("PROCESSING", bodyHash, ownerToken, null, expiresAt.toEpochMilli());
        }

        private static RedisIdempotencyRecord completed(StoredResponse response) {
            return new RedisIdempotencyRecord(
                    "COMPLETED",
                    response.bodyHash(),
                    "",
                    response,
                    response.expiresAtEpochMillis()
            );
        }

        private boolean completed() {
            return "COMPLETED".equals(state) && response != null;
        }
    }

    private static final class PendingRequest {

        private final String bodyHash;
        private final CompletableFuture<StoredResponse> completion = new CompletableFuture<>();

        private PendingRequest(String bodyHash) {
            this.bodyHash = bodyHash;
        }

        private String bodyHash() {
            return bodyHash;
        }

        private void complete(StoredResponse response) {
            completion.complete(response);
        }

        private void completeExceptionally(Throwable throwable) {
            completion.completeExceptionally(throwable);
        }

        private StoredResponse await() throws InterruptedException, ExecutionException, TimeoutException {
            return completion.get(30, TimeUnit.SECONDS);
        }
    }

    private static final class CachedBodyRequest extends HttpServletRequestWrapper {

        private final byte[] cachedBody;

        private CachedBodyRequest(HttpServletRequest request) throws IOException {
            super(request);
            this.cachedBody = StreamUtils.copyToByteArray(request.getInputStream());
        }

        private byte[] cachedBody() {
            return cachedBody;
        }

        @Override
        public ServletInputStream getInputStream() {
            return new CachedBodyServletInputStream(cachedBody);
        }

        @Override
        public BufferedReader getReader() {
            Charset charset = StringUtils.hasText(getCharacterEncoding())
                    ? Charset.forName(getCharacterEncoding())
                    : StandardCharsets.UTF_8;
            return new BufferedReader(new InputStreamReader(getInputStream(), charset));
        }
    }

    private static final class CachedBodyServletInputStream extends ServletInputStream {

        private final ByteArrayInputStream inputStream;

        private CachedBodyServletInputStream(byte[] cachedBody) {
            this.inputStream = new ByteArrayInputStream(cachedBody);
        }

        @Override
        public boolean isFinished() {
            return inputStream.available() == 0;
        }

        @Override
        public boolean isReady() {
            return true;
        }

        @Override
        public void setReadListener(ReadListener readListener) {
            // Synchronous MVC requests do not use async read callbacks here.
        }

        @Override
        public int read() {
            return inputStream.read();
        }
    }
}
