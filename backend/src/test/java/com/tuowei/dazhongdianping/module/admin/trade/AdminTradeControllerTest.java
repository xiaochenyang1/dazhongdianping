package com.tuowei.dazhongdianping.module.admin.trade;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminTradeControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void seedOrders() {
        jdbc.update(
                """
                INSERT INTO `order`(
                    id, order_no, user_id, deal_id, shop_id, region, quantity,
                    unit_price, amount, currency, pay_method, pay_status, status,
                    paid_at, created_at, updated_at
                ) VALUES
                (9301, 'ADMIN-ORDER-001', 9001, 40001, 10001, 'CN', 2, 88.00, 176.00, 'CNY', 'alipay_mock', 2, 1,
                 TIMESTAMP '2026-07-20 09:00:00', TIMESTAMP '2026-07-20 08:30:00', TIMESTAMP '2026-07-20 09:30:00'),
                (9302, 'ADMIN-ORDER-002', 9002, 40001, 10001, 'CN', 1, 88.00, 88.00, 'CNY', 'alipay_mock', 1, 1,
                 TIMESTAMP '2026-07-21 10:10:00', TIMESTAMP '2026-07-21 10:00:00', TIMESTAMP '2026-07-21 10:12:00')
                """
        );
        jdbc.update(
                """
                INSERT INTO payment(id, order_id, order_no, channel, channel_txn, amount, currency, status, created_at, updated_at) VALUES
                (9401, 9301, 'ADMIN-ORDER-001', 'alipay_mock', 'TX-ADMIN-001', 176.00, 'CNY', 1,
                 TIMESTAMP '2026-07-20 08:31:00', TIMESTAMP '2026-07-20 09:00:00'),
                (9402, 9302, 'ADMIN-ORDER-002', 'alipay_mock', 'TX-ADMIN-002', 88.00, 'CNY', 1,
                 TIMESTAMP '2026-07-21 10:01:00', TIMESTAMP '2026-07-21 10:10:00')
                """
        );
        jdbc.update(
                """
                INSERT INTO refund(id, order_id, coupon_id, amount, reason, status, audit_by, audit_reason, audited_at, created_at, updated_at) VALUES
                (9501, 9301, 0, 176.00, '行程变动', 1, 1, '审核通过', TIMESTAMP '2026-07-20 09:20:00',
                 TIMESTAMP '2026-07-20 09:10:00', TIMESTAMP '2026-07-20 09:20:00')
                """
        );
    }

    @Test
    void shouldListOrdersWithPaymentAndRefundDetails() throws Exception {
        mockMvc.perform(get("/api/admin/v1/orders")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .header("X-Region", "CN")
                        .param("page", "1")
                        .param("pageSize", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.hasMore").value(false))
                .andExpect(jsonPath("$.data.list[0].orderNo").value("ADMIN-ORDER-002"))
                .andExpect(jsonPath("$.data.list[0].merchantId").value(1001))
                .andExpect(jsonPath("$.data.list[0].merchantName").value("沪上渝里餐饮"))
                .andExpect(jsonPath("$.data.list[0].userNickname").value("欧洲咖啡客"))
                .andExpect(jsonPath("$.data.list[0].payStatusText").value("已支付"))
                .andExpect(jsonPath("$.data.list[0].paymentChannelTxn").value("TX-ADMIN-002"))
                .andExpect(jsonPath("$.data.list[1].orderNo").value("ADMIN-ORDER-001"))
                .andExpect(jsonPath("$.data.list[1].refundStatusText").value("退款成功"))
                .andExpect(jsonPath("$.data.list[1].refundAuditReason").value("审核通过"));
    }

    @Test
    void shouldFilterOrdersByRefundStatusAndDateRange() throws Exception {
        mockMvc.perform(get("/api/admin/v1/orders")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .header("X-Region", "CN")
                        .param("refundStatus", "1")
                        .param("dateFrom", "2026-07-20")
                        .param("dateTo", "2026-07-20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].orderNo").value("ADMIN-ORDER-001"))
                .andExpect(jsonPath("$.data.list[0].refundReason").value("行程变动"))
                .andExpect(jsonPath("$.data.list[0].paymentStatusText").value("成功"));
    }

    private String login(String account, String password) throws Exception {
        var result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"%s","password":"%s"}
                                """.formatted(account, password)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
