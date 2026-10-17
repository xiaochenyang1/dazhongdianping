package com.tuowei.dazhongdianping.module.adpromo;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.adpromo.service.AdClickDeduplicator;
import org.junit.jupiter.api.BeforeEach;
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
class AdPromoLifecycleControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Autowired private AdClickDeduplicator adClickDeduplicator;
    @Autowired private JdbcTemplate jdbc;

    private static final String KW = "zzzadtest";

    @BeforeEach
    void resetClickDedupe() {
        adClickDeduplicator.clearAll();
    }

    @Test
    void merchantCreatesAdminApprovesServesChargesAndPauses() throws Exception {
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");

        // 1) 商家为自家门店 10001 创建投放（待审核）。
        MvcResult created = mockMvc.perform(post("/api/b/v1/ads")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"name\":\"测试推广\",\"slotType\":1,\"keyword\":\"" + KW
                                + "\",\"bidCpc\":5.00,\"dailyBudget\":50.00}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(1))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        // 未过审时不投放。
        mockMvc.perform(get("/api/c/v1/ads?slotType=1&keyword=" + KW).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.campaignId==" + id + ")]").doesNotExist());

        // 2) 平台审核通过。
        String admin = adminToken();
        mockMvc.perform(post("/api/admin/v1/ads/{id}/audit", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"approved\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(2));

        // 3) 过审后进入固定广告位，带 ad 标识。
        mockMvc.perform(get("/api/c/v1/ads?slotType=1&keyword=" + KW).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.campaignId==" + id + ")].ad").value(org.hamcrest.Matchers.hasItem(true)));

        // 4) 点击计费成功。
        mockMvc.perform(post("/api/c/v1/ads/{id}/click", id).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.charged").value(true));

        // 同一匿名访客窗口内重复点击不再计费（防刷）。
        mockMvc.perform(post("/api/c/v1/ads/{id}/click", id).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.charged").value(false));

        // 5) 商家暂停后不再投放。
        mockMvc.perform(post("/api/b/v1/ads/{id}/pause", id)
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));
        mockMvc.perform(get("/api/c/v1/ads?slotType=1&keyword=" + KW).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.campaignId==" + id + ")]").doesNotExist());
    }

    @Test
    void rejectRequiresReasonThenMarksRejected() throws Exception {
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        MvcResult created = mockMvc.perform(post("/api/b/v1/ads")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"name\":\"待驳回\",\"slotType\":2,\"keyword\":\"\","
                                + "\"bidCpc\":1.00,\"dailyBudget\":0}"))
                .andExpect(status().isOk()).andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        String admin = adminToken();
        mockMvc.perform(post("/api/admin/v1/ads/{id}/audit", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"approved\":false}"))
                .andExpect(status().isBadRequest());

        mockMvc.perform(post("/api/admin/v1/ads/{id}/audit", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"approved\":false,\"rejectReason\":\"素材不合规\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(3))
                .andExpect(jsonPath("$.data.rejectReason").value("素材不合规"));
    }

    @Test
    void merchantCannotAdvertiseUnownedShop() throws Exception {
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        mockMvc.perform(post("/api/b/v1/ads")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10002,\"name\":\"越权\",\"slotType\":1,\"keyword\":\"x\","
                                + "\"bidCpc\":1.00,\"dailyBudget\":0}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void signedInViewerCannotBeChargedAgainAfterChangingIp() throws Exception {
        long campaignId = createApprovedCampaign();
        String userToken = loginUser("demo.cn@example.com");

        mockMvc.perform(post("/api/c/v1/ads/{id}/click", campaignId)
                        .header("X-Region", "CN").header("Authorization", bearer(userToken))
                        .with(request -> { request.setRemoteAddr("198.51.100.10"); return request; }))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.charged").value(true));
        mockMvc.perform(post("/api/c/v1/ads/{id}/click", campaignId)
                        .header("X-Region", "CN").header("Authorization", bearer(userToken))
                        .with(request -> { request.setRemoteAddr("203.0.113.10"); return request; }))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.charged").value(false));

        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM ad_click_log WHERE campaign_id=?",
                Integer.class, campaignId)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT user_id FROM ad_click_log WHERE campaign_id=?",
                Long.class, campaignId)).isZero();

        String secondUserToken = loginUser("+447700900999");
        mockMvc.perform(post("/api/c/v1/ads/{id}/click", campaignId)
                        .header("X-Region", "CN").header("Authorization", bearer(secondUserToken))
                        .with(request -> { request.setRemoteAddr("198.51.100.10"); return request; }))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.charged").value(true));
        assertThat(jdbc.queryForObject("SELECT total_spent FROM ad_campaign WHERE id=?",
                java.math.BigDecimal.class, campaignId)).isEqualByComparingTo("10.00");
    }

    @Test
    void anonymousClickUsesRemoteAddressAndIgnoresSpoofedForwardingHeaders() throws Exception {
        long campaignId = createApprovedCampaign();
        for (String forwardedIp : new String[] {"203.0.113.1", "203.0.113.2"}) {
            mockMvc.perform(post("/api/c/v1/ads/{id}/click", campaignId)
                            .header("X-Region", "CN").header("X-Forwarded-For", forwardedIp)
                            .with(request -> { request.setRemoteAddr("198.51.100.42"); return request; }))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.charged").value(forwardedIp.equals("203.0.113.1")));
        }
        mockMvc.perform(post("/api/c/v1/ads/{id}/click", campaignId)
                        .header("X-Region", "CN")
                        .with(request -> { request.setRemoteAddr("198.51.100.43"); return request; }))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.charged").value(true));
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM ad_click_log WHERE campaign_id=?",
                Integer.class, campaignId)).isEqualTo(2);
    }

    private long createApprovedCampaign() throws Exception {
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        MvcResult created = mockMvc.perform(post("/api/b/v1/ads")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"shopId":10001,"name":"点击去重回归","slotType":1,
                                 "keyword":"dedupe","bidCpc":5.00,"dailyBudget":50.00}
                                """))
                .andExpect(status().isOk()).andReturn();
        long campaignId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();
        mockMvc.perform(post("/api/admin/v1/ads/{id}/audit", campaignId)
                        .header("Authorization", bearer(adminToken())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"approved\":true}"))
                .andExpect(status().isOk());
        return campaignId;
    }

    private String loginUser(String account) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .header("X-Region", "CN").contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                java.util.Map.of("account", account, "password", "Demo123456"))))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String loginMerchant(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"" + password + "\"}"))
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
