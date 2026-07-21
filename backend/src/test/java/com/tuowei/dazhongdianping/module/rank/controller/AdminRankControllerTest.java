package com.tuowei.dazhongdianping.module.rank.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminRankControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldCreateDraftAndPublishNewSnapshot() throws Exception {
        String token = loginToken();
        MvcResult draft = mockMvc.perform(post("/api/admin/v1/ranks/config")
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "rankType": 1,
                                  "region": "CN",
                                  "cityId": 1,
                                  "categoryId": 102,
                                  "calcCycle": 4,
                                  "weight": {"score": 0.7, "reviewCount": 0.2, "hasDeal": 0.1},
                                  "minReviewCount": 1,
                                  "minScore": 4.0,
                                  "manualIntervene": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.version").value(2))
                .andExpect(jsonPath("$.data.statusText").value("草稿"))
                .andReturn();

        long configId = objectMapper.readTree(draft.getResponse().getContentAsString()).at("/data/id").asLong();
        mockMvc.perform(put("/api/admin/v1/ranks/config/{configId}", configId)
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "rankType": 1, "region": "CN", "cityId": 1, "categoryId": 102,
                                  "calcCycle": 4,
                                  "weight": {"score": 0.8, "reviewCount": 0.1, "hasDeal": 0.1},
                                  "minReviewCount": 1, "minScore": 4.1, "manualIntervene": true
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.minScore").value(4.1));

        mockMvc.perform(post("/api/admin/v1/ranks/config/{configId}/publish", configId)
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.config.statusText").value("已发布"))
                .andExpect(jsonPath("$.data.rankId").isNumber())
                .andExpect(jsonPath("$.data.itemCount").value(1));
    }

    @Test
    void shouldRollbackHistoricalConfigAsNewVersion() throws Exception {
        mockMvc.perform(post("/api/admin/v1/ranks/config/3001/rollback")
                        .header("Authorization", "Bearer " + loginToken())
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.config.version").value(2))
                .andExpect(jsonPath("$.data.config.statusText").value("已发布"))
                .andExpect(jsonPath("$.data.itemCount").value(1));
    }

    @Test
    void shouldRejectCrossRegionConfigAccess() throws Exception {
        mockMvc.perform(get("/api/admin/v1/ranks/config")
                        .header("Authorization", "Bearer " + loginToken())
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].region").value("EU"));

        mockMvc.perform(post("/api/admin/v1/ranks/config/3001/publish")
                        .header("Authorization", "Bearer " + loginToken())
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldRejectDisabledScopeWhenCreatingDraft() throws Exception {
        String token = loginToken();
        jdbcTemplate.update("UPDATE category SET status=0 WHERE id=202");
        mockMvc.perform(post("/api/admin/v1/ranks/config")
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rankBody("EU", 102, 202)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("分类不存在或不属于当前区域"));
    }

    @Test
    void shouldRecheckScopeBeforePublishingWithoutMutatingPublishedState() throws Exception {
        String token = loginToken();
        MvcResult draft = mockMvc.perform(post("/api/admin/v1/ranks/config")
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rankBody("EU", 101, 201)))
                .andExpect(status().isOk())
                .andReturn();
        long configId = objectMapper.readTree(draft.getResponse().getContentAsString()).at("/data/id").asLong();
        jdbcTemplate.update("UPDATE city SET status=0 WHERE id=101");

        mockMvc.perform(post("/api/admin/v1/ranks/config/{id}/publish", configId)
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "EU"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("城市不存在或不属于当前区域"));

        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT status FROM rank_config WHERE id=?", Integer.class, configId));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT status FROM rank_config WHERE id=3101", Integer.class));
        assertEquals(Boolean.TRUE, jdbcTemplate.queryForObject(
                "SELECT enabled FROM `rank` WHERE id=31001", Boolean.class));
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM `rank` WHERE config_id=?", Integer.class, configId));
    }

    private String rankBody(String region, long cityId, long categoryId) {
        return """
                {
                  "rankType":1,"region":"%s","cityId":%d,"categoryId":%d,
                  "calcCycle":4,
                  "weight":{"score":0.7,"reviewCount":0.2,"hasDeal":0.1},
                  "minReviewCount":1,"minScore":4.0,"manualIntervene":true
                }
                """.formatted(region, cityId, categoryId);
    }

    private String loginToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at("/data/accessToken").asText();
    }
}
