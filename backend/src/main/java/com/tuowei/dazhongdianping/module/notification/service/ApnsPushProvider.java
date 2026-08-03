package com.tuowei.dazhongdianping.module.notification.service;

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
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class ApnsPushProvider implements PushProvider {
    private static final String NAME = "APNs";
    private static final String PRODUCTION_ENDPOINT = "https://api.push.apple.com";
    private static final String SANDBOX_ENDPOINT = "https://api.sandbox.push.apple.com";

    private final PushProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;
    private final Object tokenLock = new Object();
    private volatile SignedToken signedToken;

    public ApnsPushProvider(PushProperties properties,
                            ObjectMapper objectMapper,
                            RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.restClient = restClientBuilder
                .baseUrl(endpoint(properties.getApns()))
                .build();
    }

    @Override
    public int channel() {
        return 2;
    }

    @Override
    public String name() {
        return NAME;
    }

    @Override
    public boolean isConfigured() {
        return properties.isEnabled() && properties.getApns().isConfigured();
    }

    @Override
    public PushSendResult send(UserDeviceRow device, PushMessage message) {
        if (!isConfigured()) {
            return PushSendResult.failed(NAME, "not_configured");
        }
        try {
            String token = authorizationToken();
            PushHttpResponse response = restClient.post()
                    .uri(uriBuilder -> uriBuilder.path("/3/device/{token}").build(device.getPushToken()))
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("authorization", "bearer " + token)
                    .header("apns-topic", properties.getApns().getTopic())
                    .header("apns-push-type", "alert")
                    .header("apns-priority", "10")
                    .body(objectMapper.writeValueAsString(payload(message)))
                    .exchange((ignoredRequest, responseMessage) -> new PushHttpResponse(
                            responseMessage.getStatusCode().value(),
                            StreamUtils.copyToString(responseMessage.getBody(), StandardCharsets.UTF_8)
                    ));
            if (response.isSuccessful()) {
                return PushSendResult.success(NAME);
            }
            String reason = apnsReason(response.body());
            if (response.status() == 410 || isInvalidTokenReason(reason)) {
                return PushSendResult.invalidToken(NAME, reason);
            }
            return response.isRetryable()
                    ? PushSendResult.retryable(NAME, "http_" + response.status())
                    : PushSendResult.failed(NAME, reason.isEmpty() ? "http_" + response.status() : reason);
        } catch (RestClientException exception) {
            return PushSendResult.retryable(NAME, "network_error");
        } catch (Exception exception) {
            return PushSendResult.failed(NAME, "client_error");
        }
    }

    private Map<String, Object> payload(PushMessage message) {
        Map<String, Object> alert = new LinkedHashMap<>();
        alert.put("title", valueOrEmpty(message.title()));
        alert.put("body", valueOrEmpty(message.content()));
        Map<String, Object> aps = new LinkedHashMap<>();
        aps.put("alert", alert);
        aps.put("sound", "default");
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("aps", aps);
        payload.putAll(message.data());
        return payload;
    }

    private String authorizationToken() throws Exception {
        SignedToken current = signedToken;
        if (current != null && current.expiresAt().isAfter(Instant.now().plusSeconds(30))) {
            return current.value();
        }
        synchronized (tokenLock) {
            current = signedToken;
            if (current != null && current.expiresAt().isAfter(Instant.now().plusSeconds(30))) {
                return current.value();
            }
            long issuedAt = Instant.now().getEpochSecond();
            String header = base64Url(objectMapper.writeValueAsString(Map.of(
                    "alg", "ES256",
                    "kid", properties.getApns().getKeyId()
            )));
            String claims = base64Url(objectMapper.writeValueAsString(Map.of(
                    "iss", properties.getApns().getTeamId(),
                    "iat", issuedAt
            )));
            String unsigned = header + "." + claims;
            Signature signature = Signature.getInstance("SHA256withECDSA");
            signature.initSign(readPrivateKey(properties.getApns().getPrivateKey()));
            signature.update(unsigned.getBytes(StandardCharsets.UTF_8));
            String token = unsigned + "." + Base64.getUrlEncoder().withoutPadding()
                    .encodeToString(derToJose(signature.sign(), 32));
            signedToken = new SignedToken(token, Instant.ofEpochSecond(issuedAt + 1100));
            return token;
        }
    }

    private PrivateKey readPrivateKey(String pem) throws Exception {
        String encoded = pem
                .replace("\\n", "\n")
                .replace("\\r", "\r")
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        return KeyFactory.getInstance("EC").generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(encoded)));
    }

    private byte[] derToJose(byte[] der, int componentLength) {
        if (der.length < 8 || der[0] != 0x30) {
            throw new IllegalArgumentException("Invalid ECDSA signature");
        }
        int index = 2;
        int rLength = der[index + 1] & 0xff;
        byte[] r = copyComponent(der, index + 2, rLength, componentLength);
        index += 2 + rLength;
        if (der[index] != 0x02) {
            throw new IllegalArgumentException("Invalid ECDSA signature");
        }
        int sLength = der[index + 1] & 0xff;
        byte[] s = copyComponent(der, index + 2, sLength, componentLength);
        byte[] jose = new byte[componentLength * 2];
        System.arraycopy(r, 0, jose, 0, componentLength);
        System.arraycopy(s, 0, jose, componentLength, componentLength);
        return jose;
    }

    private byte[] copyComponent(byte[] der, int offset, int length, int componentLength) {
        int sourceOffset = offset;
        int sourceLength = length;
        while (sourceLength > componentLength && der[sourceOffset] == 0) {
            sourceOffset++;
            sourceLength--;
        }
        if (sourceLength > componentLength) {
            throw new IllegalArgumentException("ECDSA signature component is too large");
        }
        byte[] component = new byte[componentLength];
        System.arraycopy(der, sourceOffset, component, componentLength - sourceLength, sourceLength);
        return component;
    }

    private String apnsReason(String body) {
        if (body == null || body.isBlank()) {
            return "";
        }
        try {
            return objectMapper.readTree(body).path("reason").asText("");
        } catch (Exception ignored) {
            return "";
        }
    }

    private boolean isInvalidTokenReason(String reason) {
        return "BadDeviceToken".equals(reason)
                || "DeviceTokenNotForTopic".equals(reason)
                || "Unregistered".equals(reason);
    }

    private String endpoint(PushProperties.Apns apns) {
        return apns.getEndpoint() == null || apns.getEndpoint().isBlank()
                ? (apns.isProduction() ? PRODUCTION_ENDPOINT : SANDBOX_ENDPOINT)
                : apns.getEndpoint();
    }

    private String base64Url(String value) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(value.getBytes(StandardCharsets.UTF_8));
    }

    private String valueOrEmpty(String value) {
        return value == null ? "" : value;
    }

    private record SignedToken(String value, Instant expiresAt) {
    }
}
