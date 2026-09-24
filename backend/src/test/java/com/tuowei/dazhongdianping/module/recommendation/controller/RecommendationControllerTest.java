package com.tuowei.dazhongdianping.module.recommendation.controller;

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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class RecommendationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void feedIsPublicAndReturnsShops() throws Exception {
        mockMvc.perform(get("/api/c/v1/recommendations/feed").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].id").exists());
    }

    @Test
    void feedRespectsLimit() throws Exception {
        mockMvc.perform(get("/api/c/v1/recommendations/feed")
                        .param("limit", "1")
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
    }

    @Test
    void trackingRequiresLogin() throws Exception {
        mockMvc.perform(post("/api/c/v1/recommendations/behaviors")
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"eventType\":1,\"shopId\":1}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void behaviorAffinitySteersFeedTowardPreferredCategory() throws Exception {
        String account = "rec-affinity@example.com";
        String token = registerUser(account, "推荐偏好用户");
        Long userId = jdbcTemplate.queryForObject(
                "SELECT id FROM app_user WHERE email = ?", Long.class, account);

        // 找出 CN 区两个不同品类的店铺
        var shops = jdbcTemplate.queryForList(
                "SELECT id, category_id FROM shop WHERE region='CN' AND status=1 AND is_deleted=FALSE ORDER BY id");
        org.junit.jupiter.api.Assertions.assertFalse(shops.isEmpty(), "需要 CN 区种子店铺");
        long targetShopId = ((Number) shops.get(0).get("id")).longValue();
        long targetCategory = ((Number) shops.get(0).get("category_id")).longValue();

        // 反复对该品类下单，累计强偏好
        for (int i = 0; i < 3; i++) {
            mockMvc.perform(post("/api/c/v1/recommendations/behaviors")
                            .header("Authorization", bearer(token))
                            .header("X-Region", "CN")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"eventType\":3,\"shopId\":%d}".formatted(targetShopId)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.messageKey").value("recommendation.behavior_tracked"));
        }

        // 验证埋点已写入且品类被回填
        Integer events = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM user_behavior_event WHERE user_id=? AND category_id=?",
                Integer.class, userId, targetCategory);
        org.junit.jupiter.api.Assertions.assertEquals(3, events);

        // feed 返回结果非空（个性化路径未报错）
        mockMvc.perform(get("/api/c/v1/recommendations/feed")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].id").exists());
    }

    @Test
    void adminCanReadAndUpdateWeight() throws Exception {
        String token = adminToken();

        mockMvc.perform(get("/api/admin/v1/recommendation/weight")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.region").value("CN"))
                .andExpect(jsonPath("$.data.affinityWeight").value(40.00));

        mockMvc.perform(put("/api/admin/v1/recommendation/weight")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"affinityWeight\":50,\"qualityWeight\":20,\"popularityWeight\":20,\"distanceWeight\":10}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.recommendation_weight_saved"))
                .andExpect(jsonPath("$.data.affinityWeight").value(50));

        mockMvc.perform(get("/api/admin/v1/recommendation/weight")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.affinityWeight").value(50));
    }

    @Test
    void adminWeightRejectsOutOfRange() throws Exception {
        String token = adminToken();
        mockMvc.perform(put("/api/admin/v1/recommendation/weight")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"affinityWeight\":200,\"qualityWeight\":20,\"popularityWeight\":20,\"distanceWeight\":10}"))
                .andExpect(status().isBadRequest());
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String registerUser(String account, String nickname) throws Exception {
        String deviceId = "rec-" + account.replaceAll("[^a-zA-Z0-9]", "-");
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> {
                            request.setRemoteAddr(testIpFor(account));
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "%s"
                                }
                                """.formatted(account, deviceId)))
                .andExpect(status().isOk());

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "%s",
                                  "preferredRegion": "CN"
                                }
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(registerResult.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String testIpFor(String account) {
        int hash = account.hashCode();
        return "10.%d.%d.%d".formatted(
                Math.floorMod(hash, 223) + 1,
                Math.floorMod(hash / 223, 223) + 1,
                Math.floorMod(hash / (223 * 223), 223) + 1
        );
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }
}
