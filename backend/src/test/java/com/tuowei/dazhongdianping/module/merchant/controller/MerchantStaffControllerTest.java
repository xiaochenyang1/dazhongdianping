package com.tuowei.dazhongdianping.module.merchant.controller;

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
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "spring.datasource.url=jdbc:h2:mem:merchant-staff-test;MODE=MYSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE")
@AutoConfigureMockMvc
class MerchantStaffControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Test
    void shouldCreateScopedStaffAndInvalidateAccessWhenDisabled() throws Exception {
        String ownerToken = login("merchant_eu_sichuan@example.com", "merchant123456");
        String staffAccount = "verifier-" + UUID.randomUUID() + "@example.com";
        MvcResult created = mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Staff#123456",
                                  "name": "Coupon Verifier",
                                  "phone": "+33100000000",
                                  "email": "%s",
                                  "roleIds": [12],
                                  "shopScopeType": 2,
                                  "shopIds": [20001]
                                }
                                """.formatted(staffAccount, staffAccount)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.roles[0].code").value("coupon_operator"))
                .andExpect(jsonPath("$.data.shopIds[0]").value(20001))
                .andReturn();
        long staffId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(staffId))
                .andExpect(jsonPath("$.data.total").value(1));

        mockMvc.perform(put("/api/b/v1/staffs/{id}", staffId)
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Front Desk Verifier",
                                  "phone": "+33100000001",
                                  "email": "%s",
                                  "roleIds": [12],
                                  "shopScopeType": 2,
                                  "shopIds": [20001],
                                  "resetPassword": false
                                }
                                """.formatted(staffAccount)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Front Desk Verifier"));

        String staffToken = login(staffAccount, "Staff#123456");

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.operator.id").value(staffId))
                .andExpect(jsonPath("$.data.operator.type").value("staff"))
                .andExpect(jsonPath("$.data.permissions[0]").value("coupon:verify"));

        mockMvc.perform(get("/api/b/v1/shops")
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list.length()").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(20001));

        mockMvc.perform(put("/api/b/v1/staffs/{id}/status", staffId)
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody(staffAccount, "Staff#123456")))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldRejectShopScopeFromAnotherMerchant() throws Exception {
        mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(login("merchant_eu_sichuan@example.com", "merchant123456")))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "cross-%s@example.com",
                                  "password": "Staff#123456",
                                  "name": "Cross Shop",
                                  "phone": "+33100000000",
                                  "email": "cross@example.com",
                                  "roleIds": [12],
                                  "shopScopeType": 2,
                                  "shopIds": [20002]
                                }
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("门店范围包含无权管理的门店"));
    }

    private String login(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody(account, password)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String loginBody(String account, String password) {
        return "{\"account\":\"" + account + "\",\"password\":\"" + password + "\"}";
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
