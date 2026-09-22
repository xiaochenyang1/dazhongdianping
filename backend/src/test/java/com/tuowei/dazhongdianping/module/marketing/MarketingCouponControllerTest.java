package com.tuowei.dazhongdianping.module.marketing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
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
class MarketingCouponControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void couponCenterListsClaimableTemplatesAnonymously() throws Exception {
        mockMvc.perform(get("/api/c/v1/marketing/coupons/center").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(org.hamcrest.Matchers.greaterThanOrEqualTo(3)))
                .andExpect(jsonPath("$.data[?(@.templateId==5001)].claimable").value(org.hamcrest.Matchers.hasItem(true)));
    }

    @Test
    void claimThenSeeInWalletAndBlockOverLimit() throws Exception {
        String token = registerToken();
        // 满50减8 券每人限领 3 张。
        for (int i = 0; i < 3; i++) {
            mockMvc.perform(post("/api/c/v1/marketing/coupons/{id}/claim", 5002)
                            .header("Authorization", bearer(token)).header("X-Region", "CN"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.status").value(1));
        }
        // 第 4 次超过限领。
        mockMvc.perform(post("/api/c/v1/marketing/coupons/{id}/claim", 5002)
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("已达到每人限领数量"));

        mockMvc.perform(get("/api/c/v1/marketing/coupons/mine")
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(3));
    }

    @Test
    void appliesCouponDiscountAtOrderCreation() throws Exception {
        String token = registerToken();
        // 领满50减8 券（deal 40001 单价 88，满足门槛）。
        MvcResult claim = mockMvc.perform(post("/api/c/v1/marketing/coupons/{id}/claim", 5002)
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andReturn();
        long userCouponId = objectMapper.readTree(claim.getResponse().getContentAsString()).at("/data/id").asLong();

        // 可用券预览应包含刚领的券。
        mockMvc.perform(get("/api/c/v1/deals/{id}/usable-coupons?quantity=1", 40001)
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + userCouponId + ")].discountAmount").value(org.hamcrest.Matchers.hasItem(8.0)));

        // 下单用券：原价 88 - 8 = 80。
        MvcResult created = mockMvc.perform(post("/api/c/v1/orders")
                        .header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"dealId\":40001,\"quantity\":1,\"userCouponId\":" + userCouponId + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.originalAmount").value(88.00))
                .andExpect(jsonPath("$.data.discountAmount").value(8.00))
                .andExpect(jsonPath("$.data.amount").value(80.00))
                .andReturn();
        long orderId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        // 券已锁定为已使用并绑定订单。
        assertThat(jdbcTemplate.queryForObject(
                "SELECT status FROM user_coupon WHERE id = ?", Integer.class, userCouponId)).isEqualTo(2);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT used_order_id FROM user_coupon WHERE id = ?", Long.class, userCouponId)).isEqualTo(orderId);

        // 取消订单应释放券。
        mockMvc.perform(post("/api/c/v1/orders/{id}/cancel", orderId)
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk());
        assertThat(jdbcTemplate.queryForObject(
                "SELECT status FROM user_coupon WHERE id = ?", Integer.class, userCouponId)).isEqualTo(1);
    }

    @Test
    void rejectsCouponBelowThreshold() throws Exception {
        String token = registerToken();
        // 满100减20 券（id 5001），deal 40001 单价 88 未达门槛。
        MvcResult claim = mockMvc.perform(post("/api/c/v1/marketing/coupons/{id}/claim", 5001)
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andReturn();
        long userCouponId = objectMapper.readTree(claim.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(post("/api/c/v1/orders")
                        .header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"dealId\":40001,\"quantity\":1,\"userCouponId\":" + userCouponId + "}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("订单未达到优惠券使用门槛"));
    }

    private String registerToken() throws Exception {
        String account = "marketing-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account + "\",\"deviceId\":\"mk-test\"}"))
                .andExpect(status().isOk());
        MvcResult r = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("{\"type\":\"email\",\"account\":\"" + account + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(r.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
