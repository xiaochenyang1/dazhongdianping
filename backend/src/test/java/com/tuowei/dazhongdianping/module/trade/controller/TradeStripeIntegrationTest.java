package com.tuowei.dazhongdianping.module.trade.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.stripe.StripeClient;
import com.stripe.model.PaymentIntent;
import com.stripe.net.RequestOptions;
import com.stripe.param.PaymentIntentCreateParams;
import com.stripe.service.PaymentIntentService;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest(properties = {
        "app.payment.mock-enabled=false",
        "app.payment.stripe.enabled=true",
        "app.payment.stripe.secret-key=sk_test_integration_contract",
        "app.payment.stripe.endpoint-secret=whsec_test_secret"
})
@AutoConfigureMockMvc
class TradeStripeIntegrationTest {

    private static final String EU_REGION = "EU";
    private static final String STRIPE_SECRET = "whsec_test_secret";
    private static final String STRIPE_INTENT_ID = "pi_test_eu_contract";
    private static final String STRIPE_CLIENT_SECRET = "pi_test_eu_contract_secret";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private StripeClient stripeClient;

    private PaymentIntentService paymentIntentService;

    @BeforeEach
    void setUpStripeClient() throws Exception {
        paymentIntentService = mock(PaymentIntentService.class);
        PaymentIntent paymentIntent = mock(PaymentIntent.class);
        when(stripeClient.paymentIntents()).thenReturn(paymentIntentService);
        when(paymentIntentService.create(
                any(PaymentIntentCreateParams.class),
                any(RequestOptions.class)))
                .thenReturn(paymentIntent);
        when(paymentIntent.getId()).thenReturn(STRIPE_INTENT_ID);
        when(paymentIntent.getClientSecret()).thenReturn(STRIPE_CLIENT_SECRET);
    }

    @Test
    void shouldCompleteEuStripeOrderOnlyAfterVerifiedWebhook() throws Exception {
        String token = registerToken();
        MvcResult created = mockMvc.perform(post("/api/c/v1/orders")
                        .header("Authorization", bearer(token))
                        .header("X-Region", EU_REGION)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"dealId\":41001,\"quantity\":1}"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode orderNode = objectMapper.readTree(created.getResponse().getContentAsString()).path("data");
        long orderId = orderNode.path("id").asLong();
        String orderNo = orderNode.path("orderNo").asText();
        BigDecimal amount = orderNode.path("amount").decimalValue();

        mockMvc.perform(post("/api/c/v1/orders/{id}/pay", orderId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", EU_REGION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.channel").value("stripe"))
                .andExpect(jsonPath("$.data.channelTxn").value(STRIPE_INTENT_ID))
                .andExpect(jsonPath("$.data.clientSecret").value(STRIPE_CLIENT_SECRET));

        String payload = stripeSucceededPayload(orderNo, STRIPE_INTENT_ID, amount, "eur");
        String signature = stripeSignature(payload, STRIPE_SECRET);

        mockMvc.perform(post("/api/c/v1/pay/notify/stripe")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Stripe-Signature", signature)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.processed").value(true))
                .andExpect(jsonPath("$.data.orderNo").value(orderNo));

        mockMvc.perform(post("/api/c/v1/pay/notify/stripe")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Stripe-Signature", signature)
                        .content(payload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.processed").value(false))
                .andExpect(jsonPath("$.data.orderNo").value(orderNo));

        mockMvc.perform(get("/api/c/v1/orders/{id}", orderId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", EU_REGION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatus").value(1))
                .andExpect(jsonPath("$.data.coupons.length()").value(1));
    }

    @Test
    void shouldRejectInvalidStripeSignatureAtControllerLevel() throws Exception {
        String payload = stripeSucceededPayload("OD-EU-INVALID", STRIPE_INTENT_ID, new BigDecimal("88.00"), "eur");

        mockMvc.perform(post("/api/c/v1/pay/notify/stripe")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("Stripe-Signature", "t=1,v1=deadbeef")
                        .content(payload))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Stripe 回调签名非法"));
    }

    @Test
    void shouldRejectMockCompleteForStripeOrders() throws Exception {
        String token = registerToken();
        MvcResult created = mockMvc.perform(post("/api/c/v1/orders")
                        .header("Authorization", bearer(token))
                        .header("X-Region", EU_REGION)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"dealId\":41001,\"quantity\":1}"))
                .andExpect(status().isOk())
                .andReturn();
        long orderId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(post("/api/c/v1/orders/{id}/pay/mock-complete", orderId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", EU_REGION))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("当前渠道不是模拟支付"));

        mockMvc.perform(get("/api/c/v1/orders/{id}", orderId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", EU_REGION))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatus").value(0))
                .andExpect(jsonPath("$.data.coupons.length()").value(0));
    }

    private String registerToken() throws Exception {
        String account = "stripe-e2e-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\""
                                + account + "\",\"deviceId\":\"stripe-e2e\"}"))
                .andExpect(status().isOk());
        MvcResult registered = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(registered.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private String stripeSucceededPayload(
            String orderNo,
            String paymentIntentId,
            BigDecimal amount,
            String currency) {
        long minorUnits = amount.movePointRight(2).longValueExact();
        return "{\"id\":\"evt_test_1\",\"object\":\"event\",\"type\":\"payment_intent.succeeded\","
                + "\"api_version\":\"2024-06-20\",\"data\":{\"object\":{\"id\":\"" + paymentIntentId
                + "\",\"object\":\"payment_intent\",\"amount\":" + minorUnits
                + ",\"currency\":\"" + currency
                + "\",\"metadata\":{\"orderNo\":\"" + orderNo + "\"}}}}";
    }

    private String stripeSignature(String payload, String secret) throws Exception {
        long timestamp = java.time.Instant.now().getEpochSecond();
        String signedPayload = timestamp + "." + payload;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        String v1 = java.util.HexFormat.of().formatHex(
                mac.doFinal(signedPayload.getBytes(StandardCharsets.UTF_8)));
        return "t=" + timestamp + ",v1=" + v1;
    }
}
