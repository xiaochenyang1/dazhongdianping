package com.tuowei.dazhongdianping.module.activity;

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
class PublicActivityControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldListOnlineActivitiesWithinRegionAndCity() throws Exception {
        mockMvc.perform(get("/api/c/v1/activities")
                        .header("X-Region", "EU")
                        .param("cityId", "101"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(5001))
                .andExpect(jsonPath("$.data[0].name").value("欧洲开学季聚餐专题"))
                .andExpect(jsonPath("$.data[0].channelText").value("活动页"))
                .andExpect(jsonPath("$.data[0].typeText").value("节日活动"))
                .andExpect(jsonPath("$.data[0].itemCount").value(3));

        mockMvc.perform(get("/api/c/v1/activities")
                        .header("X-Region", "CN")
                        .param("cityId", "1")
                        .param("channel", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(5002))
                .andExpect(jsonPath("$.data[0].cityName").value("全区域"));
    }

    @Test
    void shouldHideDraftOfflineAndOutOfWindowActivities() throws Exception {
        jdbcTemplate.update("UPDATE operation_activity SET status = 0 WHERE id = 5002");
        mockMvc.perform(get("/api/c/v1/activities").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));

        jdbcTemplate.update("""
                UPDATE operation_activity
                SET status = 2,
                    start_at = TIMESTAMP '2030-01-01 00:00:00',
                    end_at = TIMESTAMP '2030-01-31 23:59:59'
                WHERE id = 5002
                """);
        mockMvc.perform(get("/api/c/v1/activities").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    void shouldReturnActivityDetailWithEnabledItemsAndResolvedLinks() throws Exception {
        mockMvc.perform(get("/api/c/v1/activities/5001").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("欧洲开学季聚餐专题"))
                .andExpect(jsonPath("$.data.items.length()").value(3))
                .andExpect(jsonPath("$.data.items[0].targetType").value(1))
                .andExpect(jsonPath("$.data.items[0].targetName").value("Maison Sichuan Paris"))
                .andExpect(jsonPath("$.data.items[0].linkUrl").value("/shops/20001"))
                .andExpect(jsonPath("$.data.items[1].linkUrl").value("/deals/41001"))
                .andExpect(jsonPath("$.data.items[2].linkUrl").value("/ranks/31001"));
    }

    @Test
    void shouldHideDisabledActivityItemsFromPublicDetail() throws Exception {
        jdbcTemplate.update("""
                INSERT INTO operation_activity_item(
                    id, activity_id, target_type, target_id, title, subtitle, image, sort, extra_json, status
                ) VALUES (
                    7099, 5001, 6, 0, '已停用外链', '不该出现在 C 端',
                    'https://placehold.co/720x420/ef4444/ffffff?text=Disabled',
                    99, '{"url":"https://promo.example.com/disabled","badge":"停用"}', 2
                )
                """);

        mockMvc.perform(get("/api/c/v1/activities/5001").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(3))
                .andExpect(jsonPath("$.data.items[?(@.id == 7099)]").isEmpty())
                .andExpect(jsonPath("$.data.items[0].id").value(7001));
    }

    @Test
    void shouldIsolateActivitiesByRegionAndRejectMissingActivity() throws Exception {
        mockMvc.perform(get("/api/c/v1/activities/5001").header("X-Region", "CN"))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/c/v1/activities/999999").header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldExposeNewlyPublishedAdminActivityToPublicApi() throws Exception {
        String token = loginToken();
        MvcResult create = mockMvc.perform(post("/api/admin/v1/operations/activities")
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "中秋夜宵专题",
                                  "code": "cn_mid_autumn_live",
                                  "cityId": 0,
                                  "channel": 1,
                                  "type": 2,
                                  "cover": "https://placehold.co/1200x720/0f172a/ffffff?text=Live+Activity",
                                  "landingUrl": "app://activity/cn_mid_autumn_live",
                                  "rule": {
                                    "audience": ["family"],
                                    "sort": "manual"
                                  },
                                  "startAt": "2026-07-01 00:00:00",
                                  "endAt": "2026-12-31 23:59:59"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long activityId = objectMapper.readTree(create.getResponse().getContentAsByteArray()).at("/data/id").asLong();

        mockMvc.perform(get("/api/c/v1/activities").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'cn_mid_autumn_live')]").isEmpty());

        mockMvc.perform(put("/api/admin/v1/operations/activities/{id}/status", activityId)
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/admin/v1/operations/activities/{id}/items", activityId)
                        .header("Authorization", "Bearer " + token)
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "targetType": 1,
                                  "targetId": 10001,
                                  "title": "中秋火锅局",
                                  "subtitle": "热汤配圆月",
                                  "image": "https://placehold.co/720x420/1d4ed8/ffffff?text=CN+Live+Shop",
                                  "sort": 1,
                                  "extra": {
                                    "badge": "热门"
                                  }
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/activities")
                        .header("X-Region", "CN")
                        .param("channel", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'cn_mid_autumn_live')].name").value("中秋夜宵专题"));

        mockMvc.perform(get("/api/c/v1/activities/{id}", activityId).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.items[0].linkUrl").value("/shops/10001"));
    }

    private String loginToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "admin",
                                  "password": "admin123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsByteArray()).at("/data/accessToken").asText();
    }
}
