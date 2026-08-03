package com.tuowei.dazhongdianping.module.notification.service;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.push.PushProvider;
import com.tuowei.dazhongdianping.config.PushProperties;
import com.tuowei.dazhongdianping.module.auth.model.UserDeviceRow;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.spec.ECGenParameterSpec;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.junit.jupiter.api.Assertions.assertTrue;

class PushProviderTest {

    @Test
    void fcmShouldExchangeServiceAccountTokenAndSendNotification() throws Exception {
        PushProperties properties = new PushProperties();
        properties.setEnabled(true);
        properties.getFcm().setProjectId("demo-project");
        properties.getFcm().setClientEmail("push@demo-project.iam.gserviceaccount.com");
        properties.getFcm().setPrivateKey(pem(rsaKeyPair().getPrivate().getEncoded()));
        properties.getFcm().setTokenUrl("https://oauth2.test/token");
        properties.getFcm().setApiBaseUrl("https://fcm.test");

        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        server.expect(requestTo("https://oauth2.test/token"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().string(containsString("grant_type=")))
                .andRespond(withSuccess("{\"access_token\":\"oauth-token\",\"expires_in\":3600}", MediaType.APPLICATION_JSON));
        server.expect(requestTo("https://fcm.test/v1/projects/demo-project/messages:send"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header(HttpHeaders.AUTHORIZATION, "Bearer oauth-token"))
                .andExpect(content().string(containsString("device-token")))
                .andRespond(withSuccess("{\"name\":\"projects/demo/messages/1\"}", MediaType.APPLICATION_JSON));

        PushProvider provider = new FcmPushProvider(properties, new ObjectMapper(), builder);
        PushSendResult result = provider.send(device(1, "device-token"), message());

        assertTrue(result.success());
        server.verify();
    }

    @Test
    void apnsShouldMarkUnregisteredTokenAsInvalid() throws Exception {
        PushProperties properties = new PushProperties();
        properties.setEnabled(true);
        properties.getApns().setTeamId("TEAM123");
        properties.getApns().setKeyId("KEY123");
        properties.getApns().setPrivateKey(pem(ecKeyPair().getPrivate().getEncoded()));
        properties.getApns().setTopic("com.example.app");
        properties.getApns().setEndpoint("https://apns.test");

        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        server.expect(requestTo("https://apns.test/3/device/apns-token"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("apns-topic", "com.example.app"))
                .andExpect(header(HttpHeaders.AUTHORIZATION, containsString("bearer ")))
                .andExpect(content().string(containsString("review.like")))
                .andRespond(withStatus(org.springframework.http.HttpStatus.GONE)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body("{\"reason\":\"Unregistered\"}"));

        PushProvider provider = new ApnsPushProvider(properties, new ObjectMapper(), builder);
        PushSendResult result = provider.send(device(2, "apns-token"), message());

        assertTrue(result.invalidToken());
        server.verify();
    }

    private PushMessage message() {
        return new PushMessage(99L, "review.like", "Title", "Body", "/reviews/9", "EU");
    }

    private UserDeviceRow device(int channel, String token) {
        UserDeviceRow row = new UserDeviceRow();
        row.setPushChannel(channel);
        row.setPushToken(token);
        return row;
    }

    private KeyPair rsaKeyPair() throws Exception {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);
        return generator.generateKeyPair();
    }

    private KeyPair ecKeyPair() throws Exception {
        KeyPairGenerator generator = KeyPairGenerator.getInstance("EC");
        generator.initialize(new ECGenParameterSpec("secp256r1"));
        return generator.generateKeyPair();
    }

    private String pem(byte[] encoded) {
        return "-----BEGIN PRIVATE KEY-----\n"
                + Base64.getMimeEncoder(64, "\n".getBytes(StandardCharsets.US_ASCII)).encodeToString(encoded)
                + "\n-----END PRIVATE KEY-----";
    }
}
