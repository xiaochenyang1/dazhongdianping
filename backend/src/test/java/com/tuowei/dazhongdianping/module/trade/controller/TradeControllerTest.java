package com.tuowei.dazhongdianping.module.trade.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional @SpringBootTest @AutoConfigureMockMvc
class TradeControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldCompleteOrderPaymentCouponAndRefundFlow() throws Exception {
        String token = registerToken();
        mockMvc.perform(get("/api/c/v1/shops/10001/deals").header("X-Region", "CN"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].id").value(40001));
        mockMvc.perform(get("/api/c/v1/deals/40001").header("X-Region", "CN"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.items.length()").value(2));

        MvcResult created = mockMvc.perform(post("/api/c/v1/orders").header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"dealId\":40001,\"quantity\":2}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.amount").value(176.00)).andReturn();
        JsonNode order = objectMapper.readTree(created.getResponse().getContentAsString()).path("data");
        long orderId = order.path("id").asLong(); String orderNo = order.path("orderNo").asText();

        MvcResult pay = mockMvc.perform(post("/api/c/v1/orders/{id}/pay", orderId).header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.channel").value("alipay_mock")).andReturn();
        String channelTxn = objectMapper.readTree(pay.getResponse().getContentAsString()).at("/data/channelTxn").asText();
        String signature = sign(orderNo, channelTxn, "SUCCESS", "176.00");
        String notifyBody = "{\"orderNo\":\""+orderNo+"\",\"channelTxn\":\""+channelTxn+"\",\"status\":\"SUCCESS\",\"amount\":176.00,\"signature\":\""+signature+"\"}";
        for (int i=0;i<2;i++) mockMvc.perform(post("/api/c/v1/pay/notify/alipay_mock").contentType(MediaType.APPLICATION_JSON).content(notifyBody)).andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/orders/{id}", orderId).header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.payStatus").value(1)).andExpect(jsonPath("$.data.coupons.length()").value(2));
        mockMvc.perform(get("/api/c/v1/coupons").header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(2));

        mockMvc.perform(post("/api/c/v1/orders/{id}/refund", orderId).header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"行程有变\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatus").value(1))
                .andExpect(jsonPath("$.data.refund.status").value(0));
        mockMvc.perform(get("/api/c/v1/coupons").header("Authorization", bearer(token)).header("X-Region", "CN").param("status", "1"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(2));

        mockMvc.perform(post("/api/c/v1/orders/{id}/refund", orderId).header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"重复申请\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("订单已有退款申请"));
    }

    @Test
    void shouldGrantGrowthForPaidOrderOnlyOnce() throws Exception {
        jdbcTemplate.update("UPDATE growth_rule SET growth_value = 11, points = 4, daily_limit = 0, enabled = TRUE WHERE action = 'order_complete'");
        String account = "trade-growth-" + UUID.randomUUID() + "@example.com";
        String token = registerToken(account);

        MvcResult created = mockMvc.perform(post("/api/c/v1/orders").header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"dealId\":40001,\"quantity\":1}"))
                .andExpect(status().isOk()).andReturn();
        JsonNode order = objectMapper.readTree(created.getResponse().getContentAsString()).path("data");
        long orderId = order.path("id").asLong(); String orderNo = order.path("orderNo").asText();

        MvcResult pay = mockMvc.perform(post("/api/c/v1/orders/{id}/pay", orderId).header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andReturn();
        String channelTxn = objectMapper.readTree(pay.getResponse().getContentAsString()).at("/data/channelTxn").asText();
        String signature = sign(orderNo, channelTxn, "SUCCESS", "88.00");
        String notifyBody = "{\"orderNo\":\""+orderNo+"\",\"channelTxn\":\""+channelTxn+"\",\"status\":\"SUCCESS\",\"amount\":88.00,\"signature\":\""+signature+"\"}";

        for (int i=0;i<2;i++) mockMvc.perform(post("/api/c/v1/pay/notify/alipay_mock").contentType(MediaType.APPLICATION_JSON).content(notifyBody)).andExpect(status().isOk());

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM growth_points_log WHERE user_id = (SELECT id FROM app_user WHERE email = ?) AND action = 'order_complete' AND biz_id = ?",
                Long.class,
                account,
                orderId
        )).isEqualTo(2L);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT growth_value FROM app_user WHERE email = ?",
                Integer.class,
                account
        )).isEqualTo(11);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT points FROM app_user WHERE email = ?",
                Integer.class,
                account
        )).isEqualTo(4);
    }

    private String registerToken() throws Exception { return registerToken("trade-"+UUID.randomUUID()+"@example.com"); }
    private String registerToken(String account) throws Exception { mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON).content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\""+account+"\",\"deviceId\":\"trade-test\"}")).andExpect(status().isOk()); MvcResult r=mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content("{\"type\":\"email\",\"account\":\""+account+"\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}")).andExpect(status().isOk()).andReturn(); return objectMapper.readTree(r.getResponse().getContentAsString()).at("/data/accessToken").asText(); }
    private String sign(String orderNo,String txn,String status,String amount) throws Exception { String raw=orderNo+"|"+txn+"|"+status+"|"+amount+"|local-payment-notify-secret"; return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(raw.getBytes(StandardCharsets.UTF_8))); }
    private String bearer(String token){return "Bearer "+token;}
}
