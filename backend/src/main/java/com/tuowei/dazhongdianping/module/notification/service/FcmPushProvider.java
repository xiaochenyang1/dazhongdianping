package com.tuowei.dazhongdianping.module.notification.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.push.PushProvider;
import com.tuowei.dazhongdianping.config.PushProperties;
import com.tuowei.dazhongdianping.module.auth.model.UserDeviceRow;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class FcmPushProvider implements PushProvider {
    private static final String NAME = "FCM";
    private static final String TOKEN_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
    private static final String TOKEN_GRANT = "urn:ietf:params:oauth:grant-type:jwt-bearer";

    private final PushProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient apiClient;
    private final RestClient tokenClient;
    private final Object tokenLock = new Object();
    private volatile AccessToken accessToken;

    public FcmPushProvider(PushProperties properties,
                           ObjectMapper objectMapper,
                           RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.apiClient = restClientBuilder.baseUrl(properties.getFcm().getApiBaseUrl()).build();
        this.tokenClient = restClientBuilder.build();
    }

    @Override
    public int channel() {
        return 1;
    }

    @Override
    public String name() {
        return NAME;
    }

    @Override
    public boolean isConfigured() {
        return properties.isEnabled() && properties.getFcm().isConfigured();
    }

    @Override
    public PushSendResult send(UserDeviceRow device, PushMessage message) {
        if (!isConfigured()) {
            return PushSendResult.failed(NAME, "not_configured");
        }
        try {
            PushHttpResponse response = sendMessage(device.getPushToken(), message, accessToken());
            if (response.isSuccessful()) {
                return PushSendResult.success(NAME);
            }
            if (response.status() == 401) {
                invalidateAccessToken();
                return PushSendResult.retryable(NAME, "unauthorized");
            }
            if (isInvalidToken(response)) {
                return PushSendResult.invalidToken(NAME, fcmErrorCode(response.body()));
            }
            return response.isRetryable()
                    ? PushSendResult.retryable(NAME, "http_" + response.status())
                    : PushSendResult.failed(NAME, "http_" + response.status());
        } catch (RestClientException exception) {
            invalidateAccessToken();
            return PushSendResult.retryable(NAME, "network_error");
        } catch (Exception exception) {
            return PushSendResult.failed(NAME, "client_error");
        }
    }

    private PushHttpResponse sendMessage(String deviceToken, PushMessage message, String bearerToken) throws Exception {
        Map<String, Object> notification = new LinkedHashMap<>();
        notification.put("title", valueOrEmpty(message.title()));
        notification.put("body", valueOrEmpty(message.content()));
        Map<String, Object> fcmMessage = new LinkedHashMap<>();
        fcmMessage.put("token", deviceToken);
        fcmMessage.put("notification", notification);
        fcmMessage.put("data", message.data());
        Map<String, Object> body = Map.of("message", fcmMessage);
        String path = "/v1/projects/" + properties.getFcm().getProjectId() + "/messages:send";
        return post(apiClient.post()
                .uri(path)
                .contentType(MediaType.APPLICATION_JSON)
                .header("Authorization", "Bearer " + bearerToken)
                .body(objectMapper.writeValueAsString(body)));
    }

    private String accessToken() throws Exception {
        AccessToken current = accessToken;
        if (current != null && current.expiresAt().isAfter(Instant.now().plusSeconds(30))) {
            return current.value();
        }
        synchronized (tokenLock) {
            current = accessToken;
            if (current != null && current.expiresAt().isAfter(Instant.now().plusSeconds(30))) {
                return current.value();
            }
            String assertion = serviceAccountAssertion();
            PushHttpResponse response = post(tokenClient.post()
                    .uri(properties.getFcm().getTokenUrl())
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body("grant_type=" + encode(TOKEN_GRANT) + "&assertion=" + encode(assertion)));
            if (!response.isSuccessful()) {
                if (response.isRetryable()) {
                    throw new RestClientException("FCM OAuth token request is retryable: " + response.status());
                }
                throw new IllegalStateException("FCM OAuth token request failed: " + response.status());
            }
            JsonNode json = objectMapper.readTree(response.body());
            String value = json.path("access_token").asText("");
            if (!StringUtils.hasText(value)) {
                throw new IllegalStateException("FCM OAuth response did not contain an access token");
            }
            long expiresIn = Math.max(60, json.path("expires_in").asLong(3600));
            accessToken = new AccessToken(value, Instant.now().plusSeconds(expiresIn));
            return value;
        }
    }

    private String serviceAccountAssertion() throws Exception {
        long issuedAt = Instant.now().getEpochSecond();
        String header = base64Url("{\"alg\":\"RS256\",\"typ\":\"JWT\"}");
        String claims = base64Url(objectMapper.writeValueAsString(Map.of(
                "iss", properties.getFcm().getClientEmail(),
                "scope", TOKEN_SCOPE,
                "aud", properties.getFcm().getTokenUrl(),
                "iat", issuedAt,
                "exp", issuedAt + 3600
        )));
        String unsigned = header + "." + claims;
        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initSign(readPrivateKey(properties.getFcm().getPrivateKey(), "RSA"));
        signature.update(unsigned.getBytes(StandardCharsets.UTF_8));
        return unsigned + "." + Base64.getUrlEncoder().withoutPadding().encodeToString(signature.sign());
    }

    private PrivateKey readPrivateKey(String pem, String algorithm) throws Exception {
        String encoded = pem
                .replace("\\n", "\n")
                .replace("\\r", "\r")
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        byte[] der = Base64.getDecoder().decode(encoded);
        return KeyFactory.getInstance(algorithm).generatePrivate(new PKCS8EncodedKeySpec(der));
    }

    private PushHttpResponse post(RestClient.RequestBodySpec request) {
        return request.exchange((ignoredRequest, response) -> new PushHttpResponse(
                response.getStatusCode().value(),
                StreamUtils.copyToString(response.getBody(), StandardCharsets.UTF_8)
        ));
    }

    private boolean isInvalidToken(PushHttpResponse response) {
        String body = response.body() == null ? "" : response.body();
        return body.contains("UNREGISTERED")
                || (response.status() == 404 && body.isBlank());
    }

    private String fcmErrorCode(String body) {
        if (body != null && body.contains("UNREGISTERED")) {
            return "UNREGISTERED";
        }
        return "INVALID_ARGUMENT";
    }

    private void invalidateAccessToken() {
        synchronized (tokenLock) {
            accessToken = null;
        }
    }

    private String base64Url(String value) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(value.getBytes(StandardCharsets.UTF_8));
    }

    private String encode(String value) {
        return java.net.URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private String valueOrEmpty(String value) {
        return value == null ? "" : value;
    }

    private record AccessToken(String value, Instant expiresAt) {
    }
}
