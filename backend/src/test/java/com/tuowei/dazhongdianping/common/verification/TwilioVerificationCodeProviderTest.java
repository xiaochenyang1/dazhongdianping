package com.tuowei.dazhongdianping.common.verification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

class TwilioVerificationCodeProviderTest {

    private static final String ACCOUNT_SID = "AC_test_account";
    private static final String AUTH_TOKEN = "twilio-test-secret";
    private static final String FROM = "+15005550006";
    private static final String TARGET = "+14155550123";

    @Test
    void shouldRequireCredentialsAndDisabledMockMode() {
        VerificationCodeProperties properties = configuredProperties();
        TwilioVerificationCodeProvider provider = fixture(properties).provider();

        assertThat(provider.isConfigured()).isTrue();
        properties.setMockEnabled(true);
        assertThat(provider.isConfigured()).isFalse();

        properties.setMockEnabled(false);
        properties.getTwilio().setAuthToken(" ");
        assertThat(provider.isConfigured()).isFalse();
    }

    @Test
    void shouldApplyIncludedAndExcludedPhonePrefixes() {
        VerificationCodeProperties properties = configuredProperties();
        TwilioVerificationCodeProvider provider = fixture(properties).provider();

        assertThat(provider.name()).isEqualTo("TWILIO");
        assertThat(provider.supports(TARGET, 2)).isTrue();
        assertThat(provider.supports("+8613800138000", 2)).isFalse();
        assertThat(provider.supports("alice@example.com", 1)).isFalse();
        assertThat(provider.supports("", 2)).isFalse();

        properties.getTwilio().setRoutePrefixes("+1, +44");
        assertThat(provider.supports("+447700900123", 2)).isTrue();
        assertThat(provider.supports("+33123456789", 2)).isFalse();
    }

    @Test
    void shouldSendUrlEncodedFormWithBasicAuthentication() {
        Fixture fixture = fixture(configuredProperties());
        String authorization = Base64.getEncoder().encodeToString(
                (ACCOUNT_SID + ":" + AUTH_TOKEN).getBytes(StandardCharsets.UTF_8)
        );
        fixture.server().expect(requestTo(
                        "https://twilio.test/2010-04-01/Accounts/" + ACCOUNT_SID + "/Messages.json"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header(HttpHeaders.AUTHORIZATION, "Basic " + authorization))
                .andExpect(header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_FORM_URLENCODED_VALUE))
                .andExpect(content().string(
                        "To=%2B14155550123&From=%2B15005550006&"
                                + "Body=Your+verification+code+is+654321.+It+expires+in+5+minutes."
                ))
                .andExpect(content().string(not(containsString(AUTH_TOKEN))))
                .andRespond(withStatus(HttpStatus.CREATED));

        fixture.provider().send(TARGET, 2, "654321", "login");

        fixture.server().verify();
    }

    @Test
    void shouldPreferMessagingServiceSidOverFromNumber() {
        VerificationCodeProperties properties = configuredProperties();
        properties.getTwilio().setFrom("");
        properties.getTwilio().setMessagingServiceSid(" MG_test_service ");
        Fixture fixture = fixture(properties);
        fixture.server().expect(requestTo(
                        "https://twilio.test/2010-04-01/Accounts/" + ACCOUNT_SID + "/Messages.json"))
                .andExpect(content().string(containsString("MessagingServiceSid=MG_test_service")))
                .andExpect(content().string(not(containsString("From="))))
                .andRespond(withSuccess());

        fixture.provider().send(TARGET, 2, "654321", "reset");

        fixture.server().verify();
    }

    @Test
    void shouldRejectUnsupportedRouteWithoutMakingRequest() {
        Fixture fixture = fixture(configuredProperties());

        assertThatThrownBy(() -> fixture.provider().send("+8613800138000", 2, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("Twilio 验证码通道未启用");
        fixture.server().verify();
    }

    @Test
    void shouldWrapRemoteFailureWithoutExposingAuthToken() {
        Fixture fixture = fixture(configuredProperties());
        fixture.server().expect(requestTo(
                        "https://twilio.test/2010-04-01/Accounts/" + ACCOUNT_SID + "/Messages.json"))
                .andRespond(withStatus(HttpStatus.UNAUTHORIZED)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body("{\"message\":\"provider rejected " + AUTH_TOKEN + "\"}"));

        assertThatThrownBy(() -> fixture.provider().send(TARGET, 2, "654321", "login"))
                .isInstanceOf(VerificationCodeSendException.class)
                .hasMessage("Twilio 验证码发送失败")
                .hasMessageNotContaining(AUTH_TOKEN)
                .hasCauseInstanceOf(RestClientException.class);
        fixture.server().verify();
    }

    private VerificationCodeProperties configuredProperties() {
        VerificationCodeProperties properties = new VerificationCodeProperties();
        properties.getTwilio().setEnabled(true);
        properties.getTwilio().setAccountSid(ACCOUNT_SID);
        properties.getTwilio().setAuthToken(AUTH_TOKEN);
        properties.getTwilio().setFrom(FROM);
        properties.getTwilio().setApiBaseUrl("https://twilio.test");
        properties.getTwilio().setRoutePrefixes("*");
        properties.getTwilio().setExcludedRoutePrefixes("+86");
        return properties;
    }

    private Fixture fixture(VerificationCodeProperties properties) {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        return new Fixture(new TwilioVerificationCodeProvider(properties, builder), server);
    }

    private record Fixture(
            TwilioVerificationCodeProvider provider,
            MockRestServiceServer server) {
    }
}
