package com.tuowei.dazhongdianping.module.auth.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.Base64;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class UserAccessTokenService {

    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder URL_DECODER = Base64.getUrlDecoder();
    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String ISSUER = "dazhongdianping-local";

    private final ObjectMapper objectMapper;
    private final byte[] secret;
    private final long accessTokenExpireSeconds;

    public UserAccessTokenService(ObjectMapper objectMapper,
                                  @Value("${app.auth.jwt-secret}") String secret,
                                  @Value("${app.auth.access-token-expire-seconds}") long accessTokenExpireSeconds) {
        this.objectMapper = objectMapper;
        this.secret = secret.getBytes(StandardCharsets.UTF_8);
        this.accessTokenExpireSeconds = accessTokenExpireSeconds;
    }

    public String issue(Long userId, Long sessionId) {
        try {
            Instant now = Instant.now();
            String header = encodeJson("""
                    {"alg":"HS256","typ":"JWT"}
                    """);
            String payload = encodeJson("""
                    {"sub":"%s","sid":"%s","iss":"%s","iat":%d,"exp":%d}
                    """.formatted(
                    userId,
                    sessionId,
                    ISSUER,
                    now.getEpochSecond(),
                    now.plusSeconds(accessTokenExpireSeconds).getEpochSecond()
            ));
            String signature = sign(header + "." + payload);
            return header + "." + payload + "." + signature;
        } catch (Exception exception) {
            throw new IllegalStateException("生成访问令牌失败", exception);
        }
    }

    public AuthenticatedAccessToken verify(String token) {
        try {
            String[] segments = token.split("\\.");
            if (segments.length != 3) {
                throw new UnauthorizedException("访问令牌不合法");
            }
            String expected = sign(segments[0] + "." + segments[1]);
            if (!MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8), segments[2].getBytes(StandardCharsets.UTF_8))) {
                throw new UnauthorizedException("访问令牌签名无效");
            }

            JsonNode payload = objectMapper.readTree(URL_DECODER.decode(segments[1]));
            if (!ISSUER.equals(payload.path("iss").asText())) {
                throw new UnauthorizedException("访问令牌发行方无效");
            }
            long exp = payload.path("exp").asLong();
            if (exp <= Instant.now().getEpochSecond()) {
                throw new UnauthorizedException("访问令牌已过期");
            }
            long userId = Long.parseLong(payload.path("sub").asText());
            long sessionId = Long.parseLong(payload.path("sid").asText());
            return new AuthenticatedAccessToken(userId, sessionId);
        } catch (UnauthorizedException exception) {
            throw exception;
        } catch (Exception exception) {
            throw new UnauthorizedException("访问令牌不合法");
        }
    }

    private String encodeJson(String json) {
        return URL_ENCODER.encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    private String sign(String value) throws NoSuchAlgorithmException, InvalidKeyException {
        Mac mac = Mac.getInstance(HMAC_ALGORITHM);
        mac.init(new SecretKeySpec(secret, HMAC_ALGORITHM));
        return URL_ENCODER.encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
    }

    public record AuthenticatedAccessToken(
            Long userId,
            Long sessionId
    ) {
    }
}
