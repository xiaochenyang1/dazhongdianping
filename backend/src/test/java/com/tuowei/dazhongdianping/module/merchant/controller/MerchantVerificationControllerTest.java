package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
class MerchantVerificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldApplyVerifiedMerchantAndExposeShopBadgeAfterAuditPass() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "merchant_cn_hotpot@example.com",
                                  "password": "merchant123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        String merchantToken = objectMapper.readTree(login.getResponse().getContentAsString())
                .at("/data/accessToken").asText();

        mockMvc.perform(get("/api/b/v1/verified-certification")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(jsonPath("$.data.statusText").value("未申请"))
                .andExpect(jsonPath("$.data.badge").isEmpty());

        mockMvc.perform(post("/api/b/v1/verified-certification/apply")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "证照齐全，服务稳定，申请认证商户标识",
                                  "evidenceUrls": [
                                    "https://cdn.example.com/verify/license.png"
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("待审核"))
                .andExpect(jsonPath("$.data.reason").value("证照齐全，服务稳定，申请认证商户标识"))
                .andExpect(jsonPath("$.data.evidenceUrls[0]").value("https://cdn.example.com/verify/license.png"));

        Long verificationId = jdbcTemplate.queryForObject(
                "SELECT id FROM merchant_verification WHERE merchant_id = 1001",
                Long.class
        );
        assertThat(verificationId).isNotNull();
        Long taskId = jdbcTemplate.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type = 9 AND biz_id = ? AND status = 0 ORDER BY id DESC LIMIT 1",
                Long.class,
                verificationId
        );
        assertThat(taskId).isNotNull();

        mockMvc.perform(get("/api/c/v1/shops/10001").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.merchantId").value(1001))
                .andExpect(jsonPath("$.data.merchantCertification").isEmpty());

        MvcResult adminLogin = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "admin",
                                  "password": "admin123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        String adminToken = objectMapper.readTree(adminLogin.getResponse().getContentAsString())
                .at("/data/accessToken").asText();

        mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("bizType", "9")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(taskId.intValue()))
                .andExpect(jsonPath("$.data.list[0].bizType").value(9))
                .andExpect(jsonPath("$.data.list[0].bizTypeText").value("认证商户"))
                .andExpect(jsonPath("$.data.list[0].submittedBy").value("沪上渝里餐饮"))
                .andExpect(jsonPath("$.data.list[0].summary").value("证照齐全，服务稳定，申请认证商户标识"));

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"材料齐全，可挂认证标\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        mockMvc.perform(get("/api/b/v1/verified-certification")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.badge.code").value("verified_merchant"))
                .andExpect(jsonPath("$.data.badge.label").value("认证商户"));

        mockMvc.perform(get("/api/c/v1/shops/10001").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.merchantId").value(1001))
                .andExpect(jsonPath("$.data.merchantCertification.code").value("verified_merchant"))
                .andExpect(jsonPath("$.data.merchantCertification.label").value("认证商户"));

        mockMvc.perform(get("/api/c/v1/shops")
                        .header("X-Region", "CN")
                        .param("page", "1")
                        .param("pageSize", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==10001)].merchantCertification.label")
                        .value(org.hamcrest.Matchers.hasItem("认证商户")));

        mockMvc.perform(get("/api/c/v1/search/shops")
                        .header("X-Region", "CN")
                        .param("keyword", "火")
                        .param("page", "1")
                        .param("pageSize", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==10001)].merchantCertification.label")
                        .value(org.hamcrest.Matchers.hasItem("认证商户")));
    }

    @Test
    void shouldRejectDuplicatePendingVerifiedMerchantApplication() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "merchant_cn_hotpot@example.com",
                                  "password": "merchant123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        String merchantToken = objectMapper.readTree(login.getResponse().getContentAsString())
                .at("/data/accessToken").asText();

        mockMvc.perform(post("/api/b/v1/verified-certification/apply")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"第一次提交认证商户申请\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        mockMvc.perform(post("/api/b/v1/verified-certification/apply")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"重复提交应被拦截\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("当前已有待审核认证商户申请"));
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
