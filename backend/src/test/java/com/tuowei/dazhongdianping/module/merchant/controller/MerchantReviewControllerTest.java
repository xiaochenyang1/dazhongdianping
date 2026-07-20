package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class MerchantReviewControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldListPublicReviewsAndPublishMerchantReply() throws Exception {
        String token = merchantToken();

        mockMvc.perform(get("/api/b/v1/reviews")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("shopId", "20001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(3))
                .andExpect(jsonPath("$.data.list[0].shopId").value(20001))
                .andExpect(jsonPath("$.data.list[0].content").value("巴黎想找正经川菜，这家至少不会让人翻白眼。"));

        mockMvc.perform(put("/api/b/v1/reviews/3/reply")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"感谢反馈，我们已经优化服务流程。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reviewId").value(3))
                .andExpect(jsonPath("$.data.merchantName").value("Maison Sichuan SARL"))
                .andExpect(jsonPath("$.data.operatorId").value(12001))
                .andExpect(jsonPath("$.data.content").value("感谢反馈，我们已经优化服务流程。"));

        mockMvc.perform(get("/api/c/v1/reviews/3")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.merchantReply.merchantName").value("Maison Sichuan SARL"))
                .andExpect(jsonPath("$.data.merchantReply.content").value("感谢反馈，我们已经优化服务流程。"));

        mockMvc.perform(put("/api/b/v1/reviews/3/reply")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"感谢提醒，我们已同步门店负责人复盘。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("感谢提醒，我们已同步门店负责人复盘。"));

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM review_merchant_reply WHERE review_id=3",
                Integer.class
        ));
    }

    @Test
    void shouldCreateSaveAndSubmitMerchantReviewAppeal() throws Exception {
        String token = merchantToken();

        MvcResult draft = mockMvc.perform(post("/api/b/v1/reviews/3/appeal-drafts")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reviewId").value(3))
                .andExpect(jsonPath("$.data.status").value(0))
                .andReturn();
        long appealId = objectMapper.readTree(draft.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(put("/api/b/v1/review-appeals/{appealId}", appealId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "点评内容包含与实际消费无关的人身攻击，请平台复核。",
                                  "evidenceUrls": ["https://files.example/order-proof.jpg"]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(jsonPath("$.data.reason").value("点评内容包含与实际消费无关的人身攻击，请平台复核。"));

        mockMvc.perform(post("/api/b/v1/review-appeals/{appealId}/submit", appealId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type=6 AND biz_id=? AND status=0",
                Integer.class,
                appealId
        ));

        mockMvc.perform(post("/api/b/v1/review-appeals/{appealId}/submit", appealId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldEnforceReplyAppealPermissionAndShopScope() throws Exception {
        String ownerToken = merchantToken();
        String couponOperator = createStaff(ownerToken, 12, 20001L);
        String storeManager = createStaff(ownerToken, 11, 20001L);

        mockMvc.perform(put("/api/b/v1/reviews/3/reply")
                        .header("Authorization", bearer(couponOperator))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"感谢反馈。\"}"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/api/b/v1/reviews")
                        .header("Authorization", bearer(storeManager))
                        .header("X-Region", "EU")
                        .param("shopId", "20002"))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/b/v1/reviews/4/appeal-drafts")
                        .header("Authorization", bearer(storeManager))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    private String createStaff(String ownerToken, long roleId, long shopId) throws Exception {
        String account = "review-staff-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Staff#123456",
                                  "name": "Review Staff",
                                  "phone": "+33100000009",
                                  "email": "%s",
                                  "roleIds": [%d],
                                  "shopScopeType": 2,
                                  "shopIds": [%d]
                                }
                                """.formatted(account, account, roleId, shopId)))
                .andExpect(status().isOk());
        return loginMerchant(account, "Staff#123456");
    }

    private String merchantToken() throws Exception {
        return loginMerchant("merchant_eu_sichuan@example.com", "merchant123456");
    }

    private String loginMerchant(String account, String password) throws Exception {
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
}
