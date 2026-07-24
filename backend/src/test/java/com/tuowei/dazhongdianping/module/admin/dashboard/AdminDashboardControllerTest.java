package com.tuowei.dazhongdianping.module.admin.dashboard;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
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
class AdminDashboardControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void shouldReturnDashboardOverviewForAdmin() throws Exception {
        jdbc.update(
                """
                INSERT INTO `order`(
                    id, order_no, user_id, deal_id, shop_id, region, quantity,
                    unit_price, amount, currency, pay_method, pay_status, status,
                    paid_at, created_at, updated_at
                ) VALUES
                (9801, 'DASH-ORDER-001', 9001, 40001, 10001, 'CN', 1, 88.00, 88.00, 'CNY', 'alipay_mock', 1, 1,
                 CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """
        );
        jdbc.update(
                """
                INSERT INTO refund(id, order_id, coupon_id, amount, reason, status, audit_by, audit_reason, audited_at, created_at, updated_at)
                VALUES (9901, 9801, 0, 88.00, '测试退款', 0, 0, '', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """
        );
        jdbc.update(
                """
                INSERT INTO audit_task(biz_type, biz_id, region, machine_result, status, auditor_id, remark)
                VALUES (2, 40001, 'CN', 0, 0, 0, '')
                """
        );

        mockMvc.perform(get("/api/admin/v1/dashboard/overview")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.region").value("CN"))
                .andExpect(jsonPath("$.data.shopCount").isNumber())
                .andExpect(jsonPath("$.data.paidOrderCount").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.pendingRefundCount").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.pendingAuditTaskCount").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.pendingAuditBreakdown").isArray());
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
