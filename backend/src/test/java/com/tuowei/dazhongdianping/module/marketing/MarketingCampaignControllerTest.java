package com.tuowei.dazhongdianping.module.marketing;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class MarketingCampaignControllerTest {

    private static final String WINDOW = "\"startAt\":\"2026-01-01T00:00:00\",\"endAt\":\"2027-01-01T00:00:00\"";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void merchantCouponStaysHiddenUntilApprovedThenClaimable() throws Exception {
        String merchant = loginMerchant();
        String admin = adminToken();
        MvcResult created = mockMvc.perform(post("/api/b/v1/marketing/coupons")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"门店满30减5\",\"type\":1,\"thresholdAmount\":30,\"discountAmount\":5,"
                                + "\"shopId\":10001,\"totalQuantity\":10,\"perUserLimit\":1,\"validDays\":7}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(1))
                .andExpect(jsonPath("$.data.currency").value("CNY"))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/c/v1/marketing/coupons/center").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.templateId==" + id + ")]").doesNotExist());
        String user = registerUser();
        mockMvc.perform(post("/api/c/v1/marketing/coupons/{id}/claim", id)
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/admin/v1/marketing/coupon-templates/{id}/audit", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"approve\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(2));

        mockMvc.perform(get("/api/c/v1/marketing/coupons/center").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.templateId==" + id + ")].claimable").value(Matchers.hasItem(true)));
        mockMvc.perform(post("/api/c/v1/marketing/coupons/{id}/claim", id)
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("marketing.coupon_claimed"));
    }

    @Test
    void seckillClaimIsOnceAndStopsWhenSoldOut() throws Exception {
        String merchant = loginMerchant();
        String admin = adminToken();
        MvcResult created = mockMvc.perform(post("/api/b/v1/marketing/seckill")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"dealId\":40001,\"title\":\"午市秒杀\",\"seckillPrice\":9.90,\"stock\":1,"
                                + WINDOW + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(1))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/c/v1/marketing/seckill").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")]").doesNotExist());

        mockMvc.perform(get("/api/admin/v1/marketing/seckill")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")].auditStatus").value(Matchers.hasItem(1)))
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")].title").value(Matchers.hasItem("午市秒杀")))
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")].stock").value(Matchers.hasItem(1)));

        mockMvc.perform(post("/api/admin/v1/marketing/seckill/{id}/audit", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"approve\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(2));

        mockMvc.perform(get("/api/b/v1/marketing/seckill?shopId=10001")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")]").exists());
        mockMvc.perform(get("/api/c/v1/marketing/seckill").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")]").exists());

        String first = registerUser();
        mockMvc.perform(post("/api/c/v1/marketing/seckill/{id}/claim", id)
                        .header("Authorization", bearer(first)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("marketing.seckill_claimed"))
                .andExpect(jsonPath("$.data.sold").value(1));
        mockMvc.perform(post("/api/c/v1/marketing/seckill/{id}/claim", id)
                        .header("Authorization", bearer(first)).header("X-Region", "CN"))
                .andExpect(status().isBadRequest());

        String second = registerUser();
        mockMvc.perform(post("/api/c/v1/marketing/seckill/{id}/claim", id)
                        .header("Authorization", bearer(second)).header("X-Region", "CN"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void groupBuyOpensAndSucceedsWhenFull() throws Exception {
        String merchant = loginMerchant();
        String admin = adminToken();
        MvcResult created = mockMvc.perform(post("/api/b/v1/marketing/groupbuy")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"dealId\":40001,\"title\":\"双人团\",\"groupPrice\":19.90,\"groupSize\":2,"
                                + WINDOW + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(1))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/admin/v1/marketing/groupbuy")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")].auditStatus").value(Matchers.hasItem(1)))
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")].groupSize").value(Matchers.hasItem(2)));

        mockMvc.perform(post("/api/admin/v1/marketing/groupbuy/{id}/audit", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"approve\":false}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/admin/v1/marketing/groupbuy/{id}/audit", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"approve\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(2));

        mockMvc.perform(get("/api/c/v1/marketing/groupbuy").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + id + ")].groupSize").value(Matchers.hasItem(2)));

        String leader = registerUser();
        MvcResult opened = mockMvc.perform(post("/api/c/v1/marketing/groupbuy/{id}/teams", id)
                        .header("Authorization", bearer(leader)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("marketing.group_opened"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.memberCount").value(1))
                .andReturn();
        long teamId = objectMapper.readTree(opened.getResponse().getContentAsString()).at("/data/id").asLong();

        String member = registerUser();
        mockMvc.perform(post("/api/c/v1/marketing/groupbuy/teams/{teamId}/join", teamId)
                        .header("Authorization", bearer(member)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("marketing.group_joined"))
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.memberCount").value(2));
        mockMvc.perform(post("/api/c/v1/marketing/groupbuy/teams/{teamId}/join", teamId)
                        .header("Authorization", bearer(member)).header("X-Region", "CN"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void merchantCannotCreateCampaignForUnownedShopOrDeal() throws Exception {
        String merchant = loginMerchant();
        mockMvc.perform(post("/api/b/v1/marketing/seckill")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":20001,\"dealId\":40001,\"title\":\"越权\",\"seckillPrice\":1,\"stock\":1,"
                                + WINDOW + "}"))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/b/v1/marketing/groupbuy")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"dealId\":41001,\"title\":\"错套餐\",\"groupPrice\":1,\"groupSize\":2,"
                                + WINDOW + "}"))
                .andExpect(status().isBadRequest());
    }

    private String registerUser() throws Exception {
        String account = "mkt-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"marketing-test\"}"))
                .andExpect(status().isOk());
        MvcResult registered = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(registered.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String loginMerchant() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"merchant_cn_hotpot@example.com\",\"password\":\"merchant123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
