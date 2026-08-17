package com.tuowei.dazhongdianping.common.verification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

class AliyunSmsVerificationCodeProviderTest {

    private static final String ACCESS_KEY_ID = "aliyun-test-access-key";
    private static final String ACCESS_KEY_SECRET = "aliyun-test-secret";
    private static final String TARGET = "+86 138-0013-8000";

    @Test
    void shouldRequireCompleteCredentialsAndDisabledMockMode() {
        VerificationCodeProperties properties = configuredProperties();
        AliyunSmsVerificationCodeProvider provider = fixture(properties).provider();

        assertThat(provider.isConfigured()).isTrue();
        properties.setMockEnabled(true);
        assertThat(provider.isConfigured()).isFalse();

        properties.setMockEnabled(false);
        properties.getAliyun().setAccessKeySecret(" ");
        assertThat(provider.isConfigured()).isFalse();
    }

    @Test
    void shouldRouteOnlyConfiguredChinesePhonePrefixes() {
        VerificationCodeProperties properties = configuredProperties();
        AliyunSmsVerificationCodeProvider provider = fixture(properties).provider();

        assertThat(provider.name()).isEqualTo("ALIYUN_SMS");
        assertThat(provider.supports("+8613800138000", 2)).isTrue();
        assertThat(provider.supports("+14155550123", 2)).isFalse();
        assertThat(provider.supports("+8613800138000", 1)).isFalse();
        assertThat(provider.supports("", 2)).isFalse();

        properties.getAliyun().setRoutePrefixes("+86, +852");
        assertThat(provider.supports("+85291234567", 2)).isTrue();
    }

    @Test
    void shouldBuildSignedRequestNormalizePhoneAndKeepSecretOutOfUrl() throws Exception {
        Fixture fixture = fixture(configuredProperties());
        fixture.server().expect(request -> {
                    assertThat(request.getMethod()).isEqualTo(HttpMethod.POST);
                    assertThat(request.getURI().getScheme()).isEqualTo("https");
                    assertThat(request.getURI().getHost()).isEqualTo("aliyun.test");
                    assertThat(request.getURI().getPath()).isEqualTo("/");
                    assertThat(request.getURI().toString()).doesNotContain(ACCESS_KEY_SECRET);

                    Map<String, String> parameters = queryParameters(request.getURI().getRawQuery());
                    assertThat(parameters).containsEntry("AccessKeyId", ACCESS_KEY_ID)
                            .containsEntry("Action", "SendSms")
                            .containsEntry("Format", "JSON")
                            .containsEntry("PhoneNumbers", "13800138000")
                            .containsEntry("RegionId", "cn-hangzhou")
                            .containsEntry("SignatureMethod", "HMAC-SHA1")
                            .containsEntry("SignatureVersion", "1.0")
                            .containsEntry("SignName", "Dianping Test")
                            .containsEntry("TemplateCode", "SMS_TEST_001")
                            .containsEntry("TemplateParam", "{\"code\":\"654321\"}")
                            .containsEntry("Version", "2017-05-25");
                    assertThat(parameters.get("SignatureNonce")).isNotBlank();
                    assertThat(parameters.get("Timestamp"))
                            .matches("\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z");

                    String actualSignature = parameters.remove("Signature");
                    assertThat(actualSignature).isNotBlank();
                    assertThat(actualSignature).isEqualTo(signature(parameters, ACCESS_KEY_SECRET));
                })
                .andRespond(withSuccess("{\"Code\":\"OK\",\"RequestId\":\"request-1\"}",
                        MediaType.APPLICATION_JSON));

        fixture.provider().send(TARGET, 2, "654321", "register");

        fixture.server().verify();
    }

    @Test
    void shouldPercentEncodePlusInSignatureAndJsonQueryValues() throws Exception {
        AliyunSmsVerificationCodeProvider provider = fixture(configuredProperties()).provider();
        Method requestUri = AliyunSmsVerificationCodeProvider.class
                .getDeclaredMethod("requestUri", Map.class);
        requestUri.setAccessible(true);
        Map<String, String> parameters = new LinkedHashMap<>();
        parameters.put("Signature", "abc+def==");
        parameters.put("TemplateParam", "{\"code\":\"a b\"}");

        java.net.URI uri = (java.net.URI) requestUri.invoke(provider, parameters);

        assertThat(uri.getRawQuery())
                .contains("Signature=abc%2Bdef%3D%3D")
                .contains("TemplateParam=%7B%22code%22%3A%22a%20b%22%7D")
                .doesNotContain("Signature=abc+def");
    }

    @Test
    void shouldRejectUnsupportedRouteWithoutMakingRequest() {
        Fixture fixture = fixture(configuredProperties());

        assertThatThrownBy(() -> fixture.provider().send("+14155550123", 2, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("阿里云短信验证码通道未启用");
        fixture.server().verify();
    }

    @Test
    void shouldSurfaceRemoteBusinessCodeWithoutCredentialValues() {
        Fixture fixture = fixture(configuredProperties());
        fixture.server().expect(request -> assertThat(request.getURI().toString())
                        .doesNotContain(ACCESS_KEY_SECRET))
                .andRespond(withSuccess(
                        "{\"Code\":\"InvalidAccessKeyId.NotFound\",\"Message\":\"" + ACCESS_KEY_SECRET + "\"}",
                        MediaType.APPLICATION_JSON));

        assertThatThrownBy(() -> fixture.provider().send(TARGET, 2, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("阿里云短信验证码发送失败: InvalidAccessKeyId.NotFound")
                .hasMessageNotContaining(ACCESS_KEY_SECRET);
        fixture.server().verify();
    }

    @Test
    void shouldWrapHttpFailureWithoutCredentialValues() {
        Fixture fixture = fixture(configuredProperties());
        fixture.server().expect(request -> assertThat(request.getURI().toString())
                        .doesNotContain(ACCESS_KEY_SECRET))
                .andRespond(withStatus(HttpStatus.BAD_GATEWAY)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body("{\"Code\":\"ServiceUnavailable\"}"));

        assertThatThrownBy(() -> fixture.provider().send(TARGET, 2, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("阿里云短信验证码发送失败")
                .hasMessageNotContaining(ACCESS_KEY_SECRET)
                .hasCauseInstanceOf(RestClientException.class);
        fixture.server().verify();
    }

    private VerificationCodeProperties configuredProperties() {
        VerificationCodeProperties properties = new VerificationCodeProperties();
        properties.getAliyun().setEnabled(true);
        properties.getAliyun().setAccessKeyId(ACCESS_KEY_ID);
        properties.getAliyun().setAccessKeySecret(ACCESS_KEY_SECRET);
        properties.getAliyun().setSignName(" Dianping Test ");
        properties.getAliyun().setTemplateCode(" SMS_TEST_001 ");
        properties.getAliyun().setEndpoint("https://aliyun.test");
        properties.getAliyun().setRegionId(" cn-hangzhou ");
        properties.getAliyun().setRoutePrefixes("+86");
        return properties;
    }

    private Fixture fixture(VerificationCodeProperties properties) {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        return new Fixture(
                new AliyunSmsVerificationCodeProvider(properties, new ObjectMapper(), builder),
                server
        );
    }

    private Map<String, String> queryParameters(String rawQuery) {
        Map<String, String> parameters = new LinkedHashMap<>();
        for (String pair : rawQuery.split("&")) {
            String[] parts = pair.split("=", 2);
            parameters.put(
                    URLDecoder.decode(parts[0], StandardCharsets.UTF_8),
                    URLDecoder.decode(parts.length == 2 ? parts[1] : "", StandardCharsets.UTF_8)
            );
        }
        return parameters;
    }

    private String signature(Map<String, String> parameters, String secret) {
        try {
            List<Map.Entry<String, String>> entries = new ArrayList<>(parameters.entrySet());
            entries.sort(Map.Entry.comparingByKey());
            String canonicalized = entries.stream()
                    .map(entry -> percentEncode(entry.getKey()) + "=" + percentEncode(entry.getValue()))
                    .reduce((left, right) -> left + "&" + right)
                    .orElse("");
            String stringToSign = "POST&%2F&" + percentEncode(canonicalized);
            Mac mac = Mac.getInstance("HmacSHA1");
            mac.init(new SecretKeySpec(
                    (secret + "&").getBytes(StandardCharsets.UTF_8),
                    "HmacSHA1"
            ));
            return Base64.getEncoder().encodeToString(
                    mac.doFinal(stringToSign.getBytes(StandardCharsets.UTF_8))
            );
        } catch (GeneralSecurityException exception) {
            throw new AssertionError("Unable to recompute Aliyun request signature", exception);
        }
    }

    private String percentEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8)
                .replace("+", "%20")
                .replace("*", "%2A")
                .replace("%7E", "~");
    }

    private record Fixture(
            AliyunSmsVerificationCodeProvider provider,
            MockRestServiceServer server) {
    }
}
