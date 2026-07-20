package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
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

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class MerchantOrderControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldListAndApproveRefundAtomically() throws Exception {
        int originalStock = jdbc.queryForObject("SELECT stock FROM deal WHERE id=41001", Integer.class);
        PaidOrder order = createPaidOrderAndRefund();
        String merchantToken = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");

        mockMvc.perform(get("/api/b/v1/orders")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .param("shopId", "20001")
                        .param("refundStatus", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(order.orderId()))
                .andExpect(jsonPath("$.data.list[0].refund.status").value(0));

        mockMvc.perform(post("/api/b/v1/orders/{id}/refund-audit", order.orderId())
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"decision\":\"approve\",\"reason\":\"符合退款规则\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatus").value(2))
                .andExpect(jsonPath("$.data.refund.status").value(1));

        assertEquals(1, jdbc.queryForObject(
                "SELECT status FROM refund WHERE order_id=?",
                Integer.class,
                order.orderId()
        ));
        assertEquals(4, jdbc.queryForObject(
                "SELECT status FROM coupon WHERE order_id=?",
                Integer.class,
                order.orderId()
        ));
        assertEquals(originalStock, jdbc.queryForObject(
                "SELECT stock FROM deal WHERE id=41001",
                Integer.class
        ));
        assertEquals(12001L, jdbc.queryForObject(
                "SELECT operator_id FROM merchant_operation_log WHERE action='refund_approve' AND target_id=?",
                Long.class,
                order.orderId()
        ));
    }

    @Test
    void shouldEnforceRefundPermissionAndKeepOrderPaidWhenRejected() throws Exception {
        PaidOrder order = createPaidOrderAndRefund();
        String ownerToken = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");
        String serviceAccount = "order-service-" + UUID.randomUUID() + "@example.com";
        createStaff(ownerToken, serviceAccount, 13);
        String serviceToken = merchantToken(serviceAccount, "Staff#123456");

        mockMvc.perform(post("/api/b/v1/orders/{id}/refund-audit", order.orderId())
                        .header("Authorization", bearer(serviceToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"decision\":\"approve\",\"reason\":\"尝试越权\"}"))
                .andExpect(status().isUnauthorized());

        String otherMerchant = merchantToken("merchant_eu_cafe@example.com", "merchant123456");
        mockMvc.perform(post("/api/b/v1/orders/{id}/refund-audit", order.orderId())
                        .header("Authorization", bearer(otherMerchant))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"decision\":\"reject\",\"reason\":\"非本店订单\"}"))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/b/v1/orders/{id}/refund-audit", order.orderId())
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"decision\":\"reject\",\"reason\":\"已超过退款时限\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatus").value(1))
                .andExpect(jsonPath("$.data.refund.status").value(2));

        assertEquals(1, jdbc.queryForObject(
                "SELECT pay_status FROM `order` WHERE id=?",
                Integer.class,
                order.orderId()
        ));
        assertEquals(1, jdbc.queryForObject(
                "SELECT status FROM coupon WHERE order_id=?",
                Integer.class,
                order.orderId()
        ));
    }

    private PaidOrder createPaidOrderAndRefund() throws Exception {
        String userToken = userToken();
        MvcResult created = mockMvc.perform(post("/api/c/v1/orders")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"dealId\":41001,\"quantity\":1}"))
                .andExpect(status().isOk())
                .andReturn();
        long orderId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();
        mockMvc.perform(post("/api/c/v1/orders/{id}/pay/mock-complete", orderId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatus").value(1));
        mockMvc.perform(post("/api/c/v1/orders/{id}/refund", orderId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"计划有变\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.refund.status").value(0));
        return new PaidOrder(orderId);
    }

    private void createStaff(String ownerToken, String account, int roleId) throws Exception {
        mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Staff#123456",
                                  "name": "Order Service",
                                  "phone": "+33100000004",
                                  "email": "%s",
                                  "roleIds": [%d],
                                  "shopScopeType": 2,
                                  "shopIds": [20001]
                                }
                                """.formatted(account, account, roleId)))
                .andExpect(status().isOk());
    }

    private String userToken() throws Exception {
        String account = "merchant-order-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\""
                                + account + "\",\"deviceId\":\"merchant-order\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String merchantToken(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"" + password + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record PaidOrder(long orderId) {
    }
}
