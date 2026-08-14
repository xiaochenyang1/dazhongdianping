package com.tuowei.dazhongdianping.common.verification;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.UriComponentsBuilder;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class AliyunSmsVerificationCodeProvider implements VerificationCodeProvider {

    private static final DateTimeFormatter TIMESTAMP = DateTimeFormatter
            .ofPattern("yyyy-MM-dd'T'HH:mm:ss'Z'")
            .withZone(ZoneOffset.UTC);

    private final VerificationCodeProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient;

    public AliyunSmsVerificationCodeProvider(
            VerificationCodeProperties properties,
            ObjectMapper objectMapper,
            RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.objectMapper = objectMapper;
        this.restClient = restClientBuilder.baseUrl(properties.getAliyun().getEndpoint()).build();
    }

    @Override
    public String name() {
        return "ALIYUN_SMS";
    }

    @Override
    public boolean isConfigured() {
        return properties.getAliyun().isConfigured() && !properties.isMockEnabled();
    }

    @Override
    public boolean supports(String target, int targetType) {
        if (targetType != 2 || !StringUtils.hasText(target)) {
            return false;
        }
        return Arrays.stream(properties.getAliyun().getRoutePrefixes().split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .anyMatch(target::startsWith);
    }

    @Override
    public void send(String target, int targetType, String code, String scene) {
        if (!isConfigured() || !supports(target, targetType)) {
            throw new VerificationCodeSendException("阿里云短信验证码通道未启用");
        }
        Map<String, String> parameters;
        try {
            parameters = requestParameters(target, code);
            parameters.put("Signature", signature(parameters));
        } catch (Exception exception) {
            throw new VerificationCodeSendException("阿里云短信验证码签名失败", exception);
        }

        String body;
        try {
            body = restClient.post()
                    // TemplateParam contains JSON braces. Build an encoded URI first so
                    // RestClient does not interpret those braces as URI-template variables.
                    .uri(requestUri(parameters))
                    .retrieve()
                    .body(String.class);
        } catch (RestClientException | IllegalArgumentException exception) {
            throw new VerificationCodeSendException("阿里云短信验证码发送失败", exception);
        }

        JsonNode response;
        try {
            response = objectMapper.readTree(body == null ? "{}" : body);
        } catch (Exception exception) {
            throw new VerificationCodeSendException("阿里云短信验证码响应解析失败", exception);
        }
        if (!"OK".equalsIgnoreCase(response == null ? "" : response.path("Code").asText())) {
            throw new VerificationCodeSendException(
                    "阿里云短信验证码发送失败: "
                            + (response == null ? "unknown" : response.path("Code").asText("unknown"))
            );
        }
    }

    private URI requestUri(Map<String, String> parameters) {
        String endpoint = properties.getAliyun().getEndpoint().trim();
        UriComponentsBuilder uriBuilder = UriComponentsBuilder.fromUriString(endpoint);
        if (!endpoint.endsWith("/")) {
            uriBuilder.path("/");
        }
        String query = parameters.entrySet().stream()
                .map(entry -> percentEncode(entry.getKey()) + "=" + percentEncode(entry.getValue()))
                .reduce((left, right) -> left + "&" + right)
                .orElse("");
        // The query is already RFC3986-encoded. build(true) preserves `%2B`, `%7B`,
        // and other escapes instead of interpreting them as URI-template values.
        return uriBuilder.replaceQuery(query).build(true).toUri();
    }

    private Map<String, String> requestParameters(String target, String code) throws Exception {
        VerificationCodeProperties.Aliyun aliyun = properties.getAliyun();
        Map<String, String> parameters = new LinkedHashMap<>();
        parameters.put("AccessKeyId", aliyun.getAccessKeyId().trim());
        parameters.put("Action", "SendSms");
        parameters.put("Format", "JSON");
        parameters.put("PhoneNumbers", normalizePhone(target));
        parameters.put("RegionId", aliyun.getRegionId().trim());
        parameters.put("SignatureMethod", "HMAC-SHA1");
        parameters.put("SignatureNonce", UUID.randomUUID().toString());
        parameters.put("SignatureVersion", "1.0");
        parameters.put("SignName", aliyun.getSignName().trim());
        parameters.put("TemplateCode", aliyun.getTemplateCode().trim());
        parameters.put("TemplateParam", objectMapper.writeValueAsString(Map.of("code", code)));
        parameters.put("Timestamp", TIMESTAMP.format(Instant.now()));
        parameters.put("Version", "2017-05-25");
        return parameters;
    }

    private String signature(Map<String, String> parameters) throws Exception {
        List<Map.Entry<String, String>> entries = new ArrayList<>(parameters.entrySet());
        entries.sort(Map.Entry.comparingByKey());
        String canonicalized = entries.stream()
                .map(entry -> percentEncode(entry.getKey()) + "=" + percentEncode(entry.getValue()))
                .reduce((left, right) -> left + "&" + right)
                .orElse("");
        String stringToSign = "POST&%2F&" + percentEncode(canonicalized);
        Mac mac = Mac.getInstance("HmacSHA1");
        mac.init(new SecretKeySpec(
                (properties.getAliyun().getAccessKeySecret().trim() + "&")
                        .getBytes(StandardCharsets.UTF_8),
                "HmacSHA1"
        ));
        return Base64.getEncoder().encodeToString(
                mac.doFinal(stringToSign.getBytes(StandardCharsets.UTF_8))
        );
    }

    private String normalizePhone(String target) {
        String value = target.replace(" ", "").replace("-", "");
        return value.startsWith("+86") ? value.substring(3) : value;
    }

    private String percentEncode(String value) {
        return java.net.URLEncoder.encode(value, StandardCharsets.UTF_8)
                .replace("+", "%20")
                .replace("*", "%2A")
                .replace("%7E", "~");
    }
}
