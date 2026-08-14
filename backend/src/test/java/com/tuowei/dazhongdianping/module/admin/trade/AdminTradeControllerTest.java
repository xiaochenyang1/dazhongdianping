package com.tuowei.dazhongdianping.module.admin.trade;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.concurrent.atomic.AtomicLong;
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

    private static final String ADMIN_PASSWORD_HASH = "$2a$10$jqOjtTNxITz7WmpfstWxMebmoVjEFr08kLMVWRbDH3GezWSJfnqhC";
    private static final AtomicLong ADMIN_SEQUENCE = new AtomicLong(50_000);

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
                 TIMESTAMP '2026-07-20 09:10:00', TIMESTAMP '2026-07-20 09:20:00'),
                (9502, 9302, 0, 88.00, '临时有事', 0, 0, '', NULL,
                 TIMESTAMP '2026-07-21 11:00:00', TIMESTAMP '2026-07-21 11:00:00')
                """
        );
        jdbc.update(
                """
                INSERT INTO coupon(id, order_id, user_id, deal_id, shop_id, code, status, expire_at) VALUES
                (9601, 9302, 9002, 40001, 10001, 'ADMIN-COUPON-9601', 1, DATE '2026-12-31')
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

    @Test
    void shouldApproveRefundAndSettleOrder() throws Exception {
        mockMvc.perform(post("/api/admin/v1/orders/9302/refund-audit")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"decision":"approve","reason":"用户投诉属实，平台仲裁退款"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatusText").value("已退款"))
                .andExpect(jsonPath("$.data.refundStatusText").value("退款成功"))
                .andExpect(jsonPath("$.data.refundAuditReason").value("用户投诉属实，平台仲裁退款"));

        Integer couponStatus = jdbc.queryForObject("SELECT status FROM coupon WHERE id = 9601", Integer.class);
        Integer stock = jdbc.queryForObject("SELECT stock FROM deal WHERE id = 40001", Integer.class);
        Integer soldCount = jdbc.queryForObject("SELECT sold_count FROM deal WHERE id = 40001", Integer.class);
        Integer auditLogs = jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE action = 'refund_approve' AND target = 'order:9302'",
                Integer.class);
        org.assertj.core.api.Assertions.assertThat(couponStatus).isEqualTo(4);
        org.assertj.core.api.Assertions.assertThat(stock).isEqualTo(21);
        org.assertj.core.api.Assertions.assertThat(soldCount).isEqualTo(11);
        org.assertj.core.api.Assertions.assertThat(auditLogs).isEqualTo(1);
        Integer refundNotifications = jdbc.queryForObject(
                "SELECT COUNT(1) FROM user_notification WHERE user_id=9002 AND type='order.refund.result' AND title='退款已到账'",
                Integer.class);
        org.assertj.core.api.Assertions.assertThat(refundNotifications).isEqualTo(1);
    }

    @Test
    void shouldRejectRefundAndKeepOrderPaid() throws Exception {
        mockMvc.perform(post("/api/admin/v1/orders/9302/refund-audit")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"decision":"reject","reason":"证据不足，维持原判"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.payStatusText").value("已支付"))
                .andExpect(jsonPath("$.data.refundStatusText").value("已驳回"))
                .andExpect(jsonPath("$.data.refundAuditReason").value("证据不足，维持原判"));

        Integer auditLogs = jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE action = 'refund_reject' AND target = 'order:9302'",
                Integer.class);
        org.assertj.core.api.Assertions.assertThat(auditLogs).isEqualTo(1);
        Integer refundNotifications = jdbc.queryForObject(
                "SELECT COUNT(1) FROM user_notification WHERE user_id=9002 AND type='order.refund.result' AND title='退款已驳回'",
                Integer.class);
        org.assertj.core.api.Assertions.assertThat(refundNotifications).isEqualTo(1);
    }

    @Test
    void shouldRejectRefundAuditWithoutPendingApplication() throws Exception {
        mockMvc.perform(post("/api/admin/v1/orders/9301/refund-audit")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"decision":"approve","reason":"重复仲裁"}
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldFilterOrdersByCityAndShopWhitelistScopes() throws Exception {
        jdbc.update("UPDATE shop SET city_id=2, area_id=21 WHERE id=10002");
        insertPaidOrder(9304, "ADMIN-ORDER-004", 10002);

        String cityToken = scopedAdminToken("city", 1L, null);
        mockMvc.perform(get("/api/admin/v1/orders")
                        .header("Authorization", bearer(cityToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].shopId").value(10001));

        String shopToken = scopedAdminToken("shop", null, 10002L);
        mockMvc.perform(get("/api/admin/v1/orders")
                        .header("Authorization", bearer(shopToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].orderNo").value("ADMIN-ORDER-004"));
    }

    @Test
    void shouldHideOutOfScopeRefundAndForbidGlobalReconcile() throws Exception {
        String token = scopedAdminToken("restricted", null, 10002L);

        mockMvc.perform(post("/api/admin/v1/orders/9302/refund-audit")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"decision":"approve","reason":"越权请求不应生效"}
                                """))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/admin/v1/orders/reconcile")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isForbidden());

        Integer refundStatus = jdbc.queryForObject("SELECT status FROM refund WHERE id=9502", Integer.class);
        org.assertj.core.api.Assertions.assertThat(refundStatus).isZero();
    }

    @Test
    void shouldReconcileExpiredUnpaidOrdersAndPendingPayments() throws Exception {
        jdbc.update(
                """
                INSERT INTO `order`(
                    id, order_no, user_id, deal_id, shop_id, region, quantity,
                    unit_price, amount, currency, pay_method, pay_status, status,
                    paid_at, expire_at, created_at, updated_at
                ) VALUES
                (9303, 'ADMIN-ORDER-003', 9001, 40001, 10001, 'CN', 1, 88.00, 88.00, 'CNY', '', 0, 1,
                 NULL, TIMESTAMP '2020-01-01 00:00:00', TIMESTAMP '2020-01-01 00:00:00', TIMESTAMP '2020-01-01 00:00:00')
                """
        );
        jdbc.update(
                """
                INSERT INTO payment(id, order_id, order_no, channel, channel_txn, amount, currency, status, created_at, updated_at) VALUES
                (9403, 9303, 'ADMIN-ORDER-003', 'alipay_mock', 'TX-ADMIN-003', 88.00, 'CNY', 0,
                 TIMESTAMP '2020-01-01 00:00:00', TIMESTAMP '2020-01-01 00:00:00')
                """
        );
        Integer stockBefore = jdbc.queryForObject("SELECT stock FROM deal WHERE id = 40001", Integer.class);
        Integer soldBefore = jdbc.queryForObject("SELECT sold_count FROM deal WHERE id = 40001", Integer.class);

        mockMvc.perform(post("/api/admin/v1/orders/reconcile")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.closedOrders").value(1))
                .andExpect(jsonPath("$.data.restoredStockOrders").value(1))
                .andExpect(jsonPath("$.data.failedPayments").value(1))
                .andExpect(jsonPath("$.data.reconciledRefunds").value(0));

        Integer orderStatus = jdbc.queryForObject("SELECT status FROM `order` WHERE id = 9303", Integer.class);
        Integer paymentStatus = jdbc.queryForObject("SELECT status FROM payment WHERE id = 9403", Integer.class);
        Integer stockAfter = jdbc.queryForObject("SELECT stock FROM deal WHERE id = 40001", Integer.class);
        Integer soldAfter = jdbc.queryForObject("SELECT sold_count FROM deal WHERE id = 40001", Integer.class);
        Integer auditLogs = jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE action = 'trade_reconcile' AND target = 'orders'",
                Integer.class);
        org.assertj.core.api.Assertions.assertThat(orderStatus).isEqualTo(2);
        org.assertj.core.api.Assertions.assertThat(paymentStatus).isEqualTo(2);
        org.assertj.core.api.Assertions.assertThat(stockAfter).isEqualTo(stockBefore + 1);
        org.assertj.core.api.Assertions.assertThat(soldAfter).isEqualTo(soldBefore - 1);
        org.assertj.core.api.Assertions.assertThat(auditLogs).isEqualTo(1);
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
        String account = "order.scope." + suffix + "." + adminId;
        jdbc.update(
                "INSERT INTO admin_user(id,account,password_hash,name,status) VALUES (?,?,?,?,1)",
                adminId, account, ADMIN_PASSWORD_HASH, "订单范围测试管理员"
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

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
