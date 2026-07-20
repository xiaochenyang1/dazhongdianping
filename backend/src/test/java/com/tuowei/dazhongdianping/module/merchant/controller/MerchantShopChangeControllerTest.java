package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class MerchantShopChangeControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldKeepLiveShopUnchangedAndSubmitCompleteDraft() throws Exception {
        String token = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");

        MvcResult created = mockMvc.perform(post("/api/b/v1/shops/20001/change-drafts")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.changeType").value(2))
                .andExpect(jsonPath("$.data.status").value(0))
                .andReturn();
        long changeId = json(created).at("/data/id").asLong();

        mockMvc.perform(get("/api/b/v1/shop-changes")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("shopId", "20001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(changeId));

        mockMvc.perform(get("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.targetShopId").value(20001));

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(shopBody("Maison Sichuan Draft", "https://files.example/new-cover.jpg")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Maison Sichuan Draft"));

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/photos", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"photos":[
                                  {"imageUrl":"https://files.example/new-cover.jpg","photoType":1,"sort":1},
                                  {"imageUrl":"https://files.example/dining-room.jpg","photoType":2,"sort":2}
                                ]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.photos.length()").value(2));

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/dishes", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"dishes":[
                                  {"name":"水煮鱼","price":28.00,"recommendReason":"招牌","sort":1}
                                ]}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.dishes[0].name").value("水煮鱼"));

        mockMvc.perform(get("/api/c/v1/shops/20001").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Maison Sichuan Paris"));

        mockMvc.perform(post("/api/b/v1/shop-changes/{id}/submit", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type=5 AND biz_id=? AND status=0",
                Integer.class,
                changeId
        ));

        mockMvc.perform(post("/api/b/v1/shops/20001/change-drafts")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(changeId));
    }

    @Test
    void shouldEnforcePermissionAndShopScope() throws Exception {
        String ownerToken = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");
        String serviceAccount = "shop-service-" + UUID.randomUUID() + "@example.com";
        createStaff(ownerToken, serviceAccount, 13, 20001L);
        String serviceToken = merchantToken(serviceAccount, "Staff#123456");

        mockMvc.perform(post("/api/b/v1/shops/20001/change-drafts")
                        .header("Authorization", bearer(serviceToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isUnauthorized());

        String managerAccount = "shop-manager-" + UUID.randomUUID() + "@example.com";
        createStaff(ownerToken, managerAccount, 11, 20001L);
        String managerToken = merchantToken(managerAccount, "Staff#123456");

        mockMvc.perform(post("/api/b/v1/shops/20002/change-drafts")
                        .header("Authorization", bearer(managerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldValidateReferencesCurrencyCoordinatesAndPrices() throws Exception {
        String token = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");
        long changeId = createExistingDraft(token);

        assertInvalidShopBody(token, changeId, shopBody("Invalid Category", "https://files.example/a.jpg")
                .replace("\"categoryId\": 201", "\"categoryId\": 99999"));
        assertInvalidShopBody(token, changeId, shopBody("Invalid City", "https://files.example/a.jpg")
                .replace("\"cityId\": 101", "\"cityId\": 99999"));
        assertInvalidShopBody(token, changeId, shopBody("Invalid Area", "https://files.example/a.jpg")
                .replace("\"areaId\": 1011", "\"areaId\": 99999"));
        assertInvalidShopBody(token, changeId, shopBody("Invalid Currency", "https://files.example/a.jpg")
                .replace("\"currency\": \"EUR\"", "\"currency\": \"CNY\""));
        assertInvalidShopBody(token, changeId, shopBody("Invalid Latitude", "https://files.example/a.jpg")
                .replace("\"latitude\": 48.8566", "\"latitude\": 91"));
        assertInvalidShopBody(token, changeId, shopBody("Invalid Price", "https://files.example/a.jpg")
                .replace("\"pricePerCapita\": 42.00", "\"pricePerCapita\": -1"));
    }

    @Test
    void shouldValidateSnapshotLimitsAndCoverMembership() throws Exception {
        String token = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");
        long changeId = createExistingDraft(token);

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(shopBody("Snapshot Validation", "https://files.example/cover.jpg")))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/photos", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(photoBody(21)))
                .andExpect(status().isBadRequest());

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/dishes", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(dishBody(101)))
                .andExpect(status().isBadRequest());

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/photos", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"photos":[
                                  {"imageUrl":"https://files.example/cover.jpg","photoType":2,"sort":1}
                                ]}
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/b/v1/shop-changes/{id}/submit", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("门店封面必须存在于门店图相册中"));
    }

    @Test
    void shouldRejectCrossRegionAndOtherMerchantDraftAccess() throws Exception {
        String ownerToken = merchantToken("merchant_eu_sichuan@example.com", "merchant123456");
        long changeId = createExistingDraft(ownerToken);

        mockMvc.perform(get("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound());

        String otherMerchantToken = merchantToken("merchant_eu_cafe@example.com", "merchant123456");
        mockMvc.perform(get("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(otherMerchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    private long createExistingDraft(String token) throws Exception {
        MvcResult created = mockMvc.perform(post("/api/b/v1/shops/20001/change-drafts")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn();
        return json(created).at("/data/id").asLong();
    }

    private void assertInvalidShopBody(String token, long changeId, String body) throws Exception {
        mockMvc.perform(put("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    private String photoBody(int count) {
        StringBuilder body = new StringBuilder("{\"photos\":[");
        for (int index = 0; index < count; index++) {
            if (index > 0) body.append(',');
            body.append("{\"imageUrl\":\"https://files.example/photo-")
                    .append(index)
                    .append(".jpg\",\"photoType\":1,\"sort\":")
                    .append(index)
                    .append('}');
        }
        return body.append("]}").toString();
    }

    private String dishBody(int count) {
        StringBuilder body = new StringBuilder("{\"dishes\":[");
        for (int index = 0; index < count; index++) {
            if (index > 0) body.append(',');
            body.append("{\"name\":\"Dish ")
                    .append(index)
                    .append("\",\"price\":1.00,\"recommendReason\":\"Test\",\"sort\":")
                    .append(index)
                    .append('}');
        }
        return body.append("]}").toString();
    }

    private String shopBody(String name, String coverUrl) {
        return """
                {
                  "categoryId": 201,
                  "cityId": 101,
                  "areaId": 1011,
                  "name": "%s",
                  "coverUrl": "%s",
                  "phone": "+33142345678",
                  "pricePerCapita": 42.00,
                  "currency": "EUR",
                  "address": "18 Rue du Temple, Paris",
                  "latitude": 48.8566,
                  "longitude": 2.3522,
                  "businessHours": "11:30-22:30",
                  "summary": "新版门店资料",
                  "openNow": true,
                  "tags": ["Chinese", "Spicy"]
                }
                """.formatted(name, coverUrl);
    }

    private void createStaff(String ownerToken, String account, int roleId, long shopId) throws Exception {
        mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Staff#123456",
                                  "name": "Shop Operator",
                                  "phone": "+33100000006",
                                  "email": "%s",
                                  "roleIds": [%d],
                                  "shopScopeType": 2,
                                  "shopIds": [%d]
                                }
                                """.formatted(account, account, roleId, shopId)))
                .andExpect(status().isOk());
    }

    private String merchantToken(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"" + password + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return json(result).at("/data/accessToken").asText();
    }

    private JsonNode json(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
