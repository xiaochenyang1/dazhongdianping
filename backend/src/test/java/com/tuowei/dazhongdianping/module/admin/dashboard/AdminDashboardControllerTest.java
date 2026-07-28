package com.tuowei.dazhongdianping.module.admin.dashboard;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.concurrent.atomic.AtomicLong;
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

    private static final String ADMIN_PASSWORD_HASH = "$2a$10$jqOjtTNxITz7WmpfstWxMebmoVjEFr08kLMVWRbDH3GezWSJfnqhC";
    private static final AtomicLong ADMIN_SEQUENCE = new AtomicLong(60_000);

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

    @Test
    void shouldScopeShopAndTradeMetricsToAuthorizedCitiesAndShops() throws Exception {
        jdbc.update("UPDATE shop SET city_id=2, area_id=21 WHERE id=10002");
        insertPaidOrder(9802, "DASH-ORDER-002", 10001);
        insertPaidOrder(9803, "DASH-ORDER-003", 10002);
        jdbc.update(
                "INSERT INTO refund(id,order_id,coupon_id,amount,reason,status,audit_by,audit_reason,created_at,updated_at) "
                        + "VALUES (9902,9802,0,88.00,'授权门店退款',0,0,'',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),"
                        + "(9903,9803,0,88.00,'未授权门店退款',0,0,'',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"
        );

        String cityToken = scopedAdminToken("city", 1L, null);
        assertScopedMetrics(cityToken);

        String shopToken = scopedAdminToken("shop", null, 10001L);
        assertScopedMetrics(shopToken);
    }

    private void assertScopedMetrics(String token) throws Exception {
        mockMvc.perform(get("/api/admin/v1/dashboard/overview")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.shopCount").value(1))
                .andExpect(jsonPath("$.data.paidOrderCount").value(1))
                .andExpect(jsonPath("$.data.pendingRefundCount").value(1));
    }

    private void insertPaidOrder(long id, String orderNo, long shopId) {
        jdbc.update(
                """
                INSERT INTO `order`(
                    id, order_no, user_id, deal_id, shop_id, region, quantity,
                    unit_price, amount, currency, pay_method, pay_status, status,
                    paid_at, created_at, updated_at
                ) VALUES (?, ?, 9001, 40001, ?, 'CN', 1, 88.00, 88.00, 'CNY', 'alipay_mock', 1, 1,
                    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """,
                id, orderNo, shopId
        );
    }

    private String scopedAdminToken(String suffix, Long cityId, Long shopId) throws Exception {
        long adminId = ADMIN_SEQUENCE.incrementAndGet();
        String account = "dashboard.scope." + suffix + "." + adminId;
        jdbc.update(
                "INSERT INTO admin_user(id,account,password_hash,name,status) VALUES (?,?,?,?,1)",
                adminId, account, ADMIN_PASSWORD_HASH, "控制台范围测试管理员"
        );
        jdbc.update("INSERT INTO admin_user_role(admin_id,role_id) VALUES (?,5)", adminId);
        jdbc.update("INSERT INTO admin_region_scope(admin_id,region,all_cities) VALUES (?,'CN',FALSE)", adminId);
        if (cityId != null) {
            jdbc.update("INSERT INTO admin_city_scope(admin_id,region,city_id) VALUES (?,'CN',?)", adminId, cityId);
        }
        if (shopId != null) {
            jdbc.update("INSERT INTO admin_shop_scope(admin_id,region,shop_id) VALUES (?,'CN',?)", adminId, shopId);
        }
        return login(account, "admin123456");
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
