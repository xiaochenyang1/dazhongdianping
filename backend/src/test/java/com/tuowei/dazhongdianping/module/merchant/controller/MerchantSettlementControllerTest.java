package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
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
class MerchantSettlementControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldReportApprovedStatusForSeededApprovedMerchant() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "merchant_eu_sichuan@example.com",
                                  "password": "merchant123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        String token = objectMapper.readTree(login.getResponse().getContentAsString())
                .at("/data/accessToken").asText();

        mockMvc.perform(get("/api/b/v1/settle/status")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("已通过"));
    }

    @Test
    void shouldRegisterSubmitSettlementAndBlockWorkbenchUntilApproved() throws Exception {
        String account = "new-merchant-" + UUID.randomUUID() + "@example.com";
        MvcResult registered = mockMvc.perform(post("/api/b/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody(account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.account").value(account))
                .andExpect(jsonPath("$.data.auditStatus").value(0))
                .andReturn();
        String token = objectMapper.readTree(registered.getResponse().getContentAsString())
                .at("/data/accessToken").asText();

        mockMvc.perform(post("/api/b/v1/settle/apply")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "licenseUrl": "https://files.example/license.png",
                                  "legalPerson": "Alice Wang",
                                  "shopPhotoUrls": [
                                    "https://files.example/front.png",
                                    "https://files.example/hall.png"
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(jsonPath("$.data.legalPerson").value("Alice Wang"));

        mockMvc.perform(get("/api/b/v1/settle/status")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(jsonPath("$.data.shopPhotoUrls.length()").value(2));

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("商户资质尚未审核通过"));

        mockMvc.perform(post("/api/b/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody(account)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("商户账号已存在"));
    }

    private String registerBody(String account) {
        return """
                {
                  "account": "%s",
                  "password": "Merchant#123456",
                  "companyName": "Alice Foods GmbH",
                  "contactName": "Alice Wang",
                  "contactPhone": "+491234567890",
                  "region": "EU"
                }
                """.formatted(account);
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
