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
class MerchantDealControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldCreatePendingDealAndOnlyAllowOnShelfAfterAdminApproval() throws Exception {
        String merchantToken = merchantToken();
        long dealId = createDeal(merchantToken, 20001L, "双人套餐");

        mockMvc.perform(get("/api/b/v1/deals")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .param("shopId", "20001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(dealId))
                .andExpect(jsonPath("$.data.list[0].auditStatus").value(0))
                .andExpect(jsonPath("$.data.list[0].auditStatusText").value("待审核"))
                .andExpect(jsonPath("$.data.list[0].status").value(0))
                .andExpect(jsonPath("$.data.list[0].statusText").value("已下架"));

        mockMvc.perform(get("/api/b/v1/deals/{id}", dealId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(dealId))
                .andExpect(jsonPath("$.data.title").value("双人套餐"))
                .andExpect(jsonPath("$.data.items[0].name").value("主菜"))
                .andExpect(jsonPath("$.data.auditStatusText").value("待审核"));

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type=2 AND biz_id=? AND status=0",
                Integer.class,
                dealId
        ));

        changeDealStatus(merchantToken, dealId, 1)
                .andExpect(status().isBadRequest());

        Long taskId = jdbc.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=2 AND biz_id=? AND status=0",
                Long.class,
                dealId
        );
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"价格与内容合规\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bizType").value(2));

        changeDealStatus(merchantToken, dealId, 1)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));
    }

    @Test
    void shouldEnforceScopedShopAndResubmitAuditAfterEditing() throws Exception {
        String ownerToken = merchantToken();
        String staffAccount = "deal-manager-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Staff#123456",
                                  "name": "Deal Manager",
                                  "phone": "+33100000003",
                                  "email": "%s",
                                  "roleIds": [11],
                                  "shopScopeType": 2,
                                  "shopIds": [20001]
                                }
                                """.formatted(staffAccount, staffAccount)))
                .andExpect(status().isOk());
        String staffToken = loginMerchant(staffAccount, "Staff#123456");

        mockMvc.perform(post("/api/b/v1/deals")
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(dealBody(20002L, "越权套餐")))
                .andExpect(status().isNotFound());

        long dealId = createDeal(staffToken, 20001L, "初版套餐");
        mockMvc.perform(put("/api/b/v1/deals/{id}", dealId)
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(dealBody(20001L, "改版套餐")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("改版套餐"))
                .andExpect(jsonPath("$.data.auditStatus").value(0))
                .andExpect(jsonPath("$.data.status").value(0));

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type=2 AND biz_id=? AND status=0",
                Integer.class,
                dealId
        ));
    }

    private long createDeal(String token, long shopId, String title) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/deals")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(dealBody(shopId, title)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(0))
                .andExpect(jsonPath("$.data.status").value(0))
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private org.springframework.test.web.servlet.ResultActions changeDealStatus(
            String token,
            long dealId,
            int statusValue
    ) throws Exception {
        return mockMvc.perform(put("/api/b/v1/deals/{id}/status", dealId)
                .header("Authorization", bearer(token))
                .header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":" + statusValue + "}"));
    }

    private String dealBody(long shopId, String title) {
        return """
                {
                  "shopId": %d,
                  "type": 1,
                  "title": "%s",
                  "coverImage": "https://files.example/deal.jpg",
                  "price": 49.90,
                  "originalPrice": 68.00,
                  "currency": "EUR",
                  "stock": 20,
                  "validStart": "2026-07-13",
                  "validEnd": "2026-12-31",
                  "rules": "预约使用",
                  "items": [
                    {"name": "主菜", "quantity": 2, "price": 0, "sort": 1}
                  ]
                }
                """.formatted(shopId, title);
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

    private String adminToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
