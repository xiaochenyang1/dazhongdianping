package com.tuowei.dazhongdianping.module.adpromo;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
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
class AdPromoLifecycleControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    private static final String KW = "zzzadtest";

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
