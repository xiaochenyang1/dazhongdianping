package com.tuowei.dazhongdianping.module.trade.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.trade.model.CouponLifecycleResult;
import java.time.LocalDate;
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
class CouponLifecycleServiceTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private CouponLifecycleService couponLifecycleService;

    @Test
    void shouldMarkExpiredCouponsAndSendNotificationWithoutDuplication() throws Exception {
        RegisteredUser user = registerUser();
        long expiredId = insertCoupon(user.userId(), "EXP" + shortToken(), LocalDate.now().minusDays(1), 0);
        long activeId = insertCoupon(user.userId(), "ACT" + shortToken(), LocalDate.now().plusDays(10), 0);

        CouponLifecycleResult first = couponLifecycleService.processDueCoupons();
        assertEquals(1, first.expiredMarked());

        Integer expiredStatus = jdbc.queryForObject("SELECT status FROM coupon WHERE id=?", Integer.class, expiredId);
        Integer activeStatus = jdbc.queryForObject("SELECT status FROM coupon WHERE id=?", Integer.class, activeId);
        assertEquals(3, expiredStatus);
        assertEquals(1, activeStatus);

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].type").value("coupon.expired"))
                .andExpect(jsonPath("$.data.list[0].linkUrl").value(org.hamcrest.Matchers.containsString("/user/coupons?status=3&code=")));

        CouponLifecycleResult second = couponLifecycleService.processDueCoupons();
        assertEquals(0, second.expiredMarked());

        Integer notificationCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM user_notification WHERE user_id=? AND type='coupon.expired'",
                Integer.class,
                user.userId()
        );
        assertEquals(1, notificationCount);
    }

    @Test
    void shouldSendThreeDayAndOneDayRemindersWithoutDuplication() throws Exception {
        RegisteredUser user = registerUser();
        long threeDayId = insertCoupon(user.userId(), "D3" + shortToken(), LocalDate.now().plusDays(3), 0);
        long oneDayId = insertCoupon(user.userId(), "D1" + shortToken(), LocalDate.now().plusDays(1), 0);

        CouponLifecycleResult first = couponLifecycleService.processDueCoupons();
        assertEquals(1, first.threeDayReminders());
        assertEquals(1, first.oneDayReminders());

        Integer threeDayStatus = jdbc.queryForObject(
                "SELECT remind_status FROM coupon WHERE id=?",
                Integer.class,
                threeDayId
        );
        Integer oneDayStatus = jdbc.queryForObject(
                "SELECT remind_status FROM coupon WHERE id=?",
                Integer.class,
                oneDayId
        );
        assertEquals(1, threeDayStatus);
        assertEquals(2, oneDayStatus);

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[*].type").value(org.hamcrest.Matchers.everyItem(
                        org.hamcrest.Matchers.equalTo("coupon.reminder")
                )))
                .andExpect(jsonPath("$.data.list[*].linkUrl").value(org.hamcrest.Matchers.hasItems(
                        org.hamcrest.Matchers.containsString("remind=3"),
                        org.hamcrest.Matchers.containsString("remind=1")
                )));

        CouponLifecycleResult second = couponLifecycleService.processDueCoupons();
        assertEquals(0, second.threeDayReminders());
        assertEquals(0, second.oneDayReminders());
        assertEquals(0, second.expiredMarked());
        assertTrue(second.skipped() >= 0);

        Integer notificationCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM user_notification WHERE user_id=? AND type='coupon.reminder'",
                Integer.class,
                user.userId()
        );
        assertEquals(2, notificationCount);
    }

    @Test
    void shouldExpireStaleCouponsWhenListingMyCoupons() throws Exception {
        RegisteredUser user = registerUser();
        String code = "LIST" + shortToken();
        insertCoupon(user.userId(), code, LocalDate.now().minusDays(2), 0);

        mockMvc.perform(get("/api/c/v1/coupons")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN")
                        .param("status", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].status").value(3))
                .andExpect(jsonPath("$.data.list[0].statusText").value("已过期"))
                .andExpect(jsonPath("$.data.list[0].code").value(code));

        Integer status = jdbc.queryForObject(
                "SELECT status FROM coupon WHERE code=?",
                Integer.class,
                code
        );
        assertEquals(3, status);
    }

    private long insertCoupon(long userId, String code, LocalDate expireAt, int remindStatus) {
        jdbc.update("""
                INSERT INTO coupon(order_id, user_id, deal_id, shop_id, code, status, expire_at, remind_status)
                VALUES (0, ?, 40001, 10001, ?, 1, ?, ?)
                """, userId, code, expireAt, remindStatus);
        return jdbc.queryForObject("SELECT id FROM coupon WHERE code=?", Long.class, code);
    }

    private String shortToken() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
    }

    private RegisteredUser registerUser() throws Exception {
        String account = "coupon-life-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"coupon-life-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        long userId = objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/user/id").asLong();
        String accessToken = objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
        return new RegisteredUser(userId, accessToken);
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record RegisteredUser(long userId, String accessToken) {
    }
}
