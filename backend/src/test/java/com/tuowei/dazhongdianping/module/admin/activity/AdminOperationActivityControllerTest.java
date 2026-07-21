package com.tuowei.dazhongdianping.module.admin.activity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.List;
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
class AdminOperationActivityControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldCreateUpdateStatusDeleteActivitiesAndManageItemsWithinCurrentRegion() throws Exception {
        String token = loginToken("admin");
        long activityId = readId(createActivity(
                token,
                "EU",
                "巴黎开学季活动",
                "eu_school_live_test",
                101L,
                4,
                2
        ).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andReturn());

        assertThat(readValues(mockMvc.perform(get("/api/admin/v1/operations/activities")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("cityId", "101"))
                .andExpect(status().isOk())
                .andReturn(), "code"))
                .contains("eu_school_live_test");

        mockMvc.perform(put("/api/admin/v1/operations/activities/{id}", activityId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "巴黎开学季活动升级版",
                                  "code": "eu_school_live_test",
                                  "cityId": 101,
                                  "channel": 4,
                                  "type": 5,
                                  "cover": "https://placehold.co/1200x720/1d4ed8/ffffff?text=Activity+Updated",
                                  "landingUrl": "app://activity/eu_school_live_test",
                                  "rule": {
                                    "audience": ["student", "new_user"],
                                    "sort": "manual"
                                  },
                                  "startAt": "2026-09-01 00:00:00",
                                  "endAt": "2026-10-01 00:00:00"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("巴黎开学季活动升级版"))
                .andExpect(jsonPath("$.data.type").value(5))
                .andExpect(jsonPath("$.data.typeText").value("内容话题"));

        mockMvc.perform(put("/api/admin/v1/operations/activities/{id}/status", activityId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":1}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("待上线"));

        long shopItemId = readId(createItem(
                token,
                "EU",
                activityId,
                """
                        {
                          "targetType": 1,
                          "targetId": 20001,
                          "title": "留学生火锅局",
                          "subtitle": "川味聚餐稳，不用靠运气",
                          "image": "https://placehold.co/720x420/1d4ed8/ffffff?text=Shop+Item",
                          "sort": 1,
                          "extra": {
                            "badge": "热门",
                            "trackCode": "eu_school_shop_20001"
                          }
                        }
                        """
        ).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.targetName").value("Maison Sichuan Paris"))
                .andReturn());

        long externalItemId = readId(createItem(
                token,
                "EU",
                activityId,
                """
                        {
                          "targetType": 6,
                          "targetId": 0,
                          "title": "巴黎活动说明",
                          "subtitle": "学生补贴和跳转规则",
                          "image": "https://placehold.co/720x420/f97316/ffffff?text=Guide+Item",
                          "sort": 9,
                          "extra": {
                            "url": "https://promo.example.com/eu/school",
                            "badge": "说明"
                          }
                        }
                        """
        ).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.targetType").value(6))
                .andReturn());

        assertThat(readValues(mockMvc.perform(get("/api/admin/v1/operations/activities/{id}/items", activityId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn(), "title"))
                .contains("留学生火锅局", "巴黎活动说明");

        mockMvc.perform(put("/api/admin/v1/operations/activities/{id}/items/{itemId}", activityId, shopItemId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "targetType": 4,
                                  "targetId": 31001,
                                  "title": "巴黎榜单入口",
                                  "subtitle": "先看榜单再订位",
                                  "image": "https://placehold.co/720x420/0f766e/ffffff?text=Rank+Item",
                                  "sort": 2,
                                  "extra": {
                                    "trackCode": "eu_school_rank_31001"
                                  }
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.targetType").value(4))
                .andExpect(jsonPath("$.data.targetName").value("巴黎华人必吃榜"));

        mockMvc.perform(put("/api/admin/v1/operations/activities/{id}/items/{itemId}/status", activityId, externalItemId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.statusText").value("停用"));

        mockMvc.perform(delete("/api/admin/v1/operations/activities/{id}/items/{itemId}", activityId, shopItemId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        assertThat(readValues(mockMvc.perform(get("/api/admin/v1/operations/activities/{id}/items", activityId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn(), "title"))
                .contains("巴黎活动说明")
                .doesNotContain("巴黎榜单入口");

        mockMvc.perform(delete("/api/admin/v1/operations/activities/{id}", activityId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        assertThat(count("SELECT COUNT(1) FROM operation_activity WHERE id=?", activityId)).isZero();
        assertThat(count("SELECT COUNT(1) FROM operation_activity_item WHERE activity_id=?", activityId)).isZero();
    }

    @Test
    void shouldRequireWritePermissionAndRejectInvalidCityTargetOrCrossRegionMutation() throws Exception {
        String readerToken = createReadOnlyAdminAndLogin();
        mockMvc.perform(get("/api/admin/v1/operations/activities")
                        .header("Authorization", bearer(readerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        createActivity(
                readerToken,
                "EU",
                "只读不该创建",
                "eu_reader_forbidden",
                101L,
                4,
                2
        ).andExpect(status().isForbidden());

        String token = loginToken("admin");
        createActivity(
                token,
                "EU",
                "无效城市活动",
                "eu_invalid_city",
                1L,
                4,
                2
        ).andExpect(status().isConflict());

        long cnActivityId = readId(createActivity(
                token,
                "CN",
                "上海夜宵活动",
                "cn_cross_region_activity",
                1L,
                1,
                1
        ).andExpect(status().isOk()).andReturn());

        mockMvc.perform(put("/api/admin/v1/operations/activities/{id}/status", cnActivityId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isNotFound());

        long euActivityId = readId(createActivity(
                token,
                "EU",
                "巴黎无效资源活动",
                "eu_invalid_target_activity",
                101L,
                4,
                2
        ).andExpect(status().isOk()).andReturn());

        createItem(
                token,
                "EU",
                euActivityId,
                """
                        {
                          "targetType": 1,
                          "targetId": 10001,
                          "title": "跨区门店不该通过",
                          "subtitle": "这里不该成功",
                          "image": "https://placehold.co/720x420/ef4444/ffffff?text=Invalid+Shop",
                          "sort": 1,
                          "extra": {
                            "badge": "错误"
                          }
                        }
                        """
        ).andExpect(status().isBadRequest());

        createItem(
                token,
                "EU",
                euActivityId,
                """
                        {
                          "targetType": 6,
                          "targetId": 1,
                          "title": "外链参数错误",
                          "subtitle": "targetId 不能乱填",
                          "image": "https://placehold.co/720x420/ef4444/ffffff?text=Invalid+External",
                          "sort": 1,
                          "extra": {
                            "badge": "错误"
                          }
                        }
                        """
        ).andExpect(status().isBadRequest());

        createItem(
                token,
                "EU",
                euActivityId,
                """
                        {
                          "targetType": 2,
                          "targetId": 41001,
                          "title": "巴黎团购资源",
                          "subtitle": "首条有效资源",
                          "image": "https://placehold.co/720x420/7c3aed/ffffff?text=Valid+Deal",
                          "sort": 1,
                          "extra": {
                            "badge": "折扣"
                          }
                        }
                        """
        ).andExpect(status().isOk());

        createItem(
                token,
                "EU",
                euActivityId,
                """
                        {
                          "targetType": 2,
                          "targetId": 41001,
                          "title": "重复团购资源",
                          "subtitle": "同目标不该重复",
                          "image": "https://placehold.co/720x420/7c3aed/ffffff?text=Duplicate+Deal",
                          "sort": 2,
                          "extra": {
                            "badge": "重复"
                          }
                        }
                        """
        ).andExpect(status().isConflict());
    }

    @Test
    void shouldExposeActivityPermissionsAndOperationsMenu() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:activity:read')]").exists())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:activity:write')]").exists())
                .andReturn();
        String token = objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[3].children[6].path").value("/operations/activities"));
    }

    private org.springframework.test.web.servlet.ResultActions createActivity(String token,
                                                                              String region,
                                                                              String name,
                                                                              String code,
                                                                              Long cityId,
                                                                              int channel,
                                                                              int type) throws Exception {
        return mockMvc.perform(post("/api/admin/v1/operations/activities")
                .header("Authorization", bearer(token))
                .header("X-Region", region)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "name": "%s",
                          "code": "%s",
                          "cityId": %d,
                          "channel": %d,
                          "type": %d,
                          "cover": "https://placehold.co/1200x720/0f172a/ffffff?text=Activity",
                          "landingUrl": "app://activity/%s",
                          "rule": {
                            "audience": ["student"],
                            "sort": "manual"
                          },
                          "startAt": "2026-09-01 00:00:00",
                          "endAt": "2026-09-30 23:59:59"
                        }
                        """.formatted(name, code, cityId == null ? 0L : cityId, channel, type, code)));
    }

    private org.springframework.test.web.servlet.ResultActions createItem(String token,
                                                                          String region,
                                                                          long activityId,
                                                                          String body) throws Exception {
        return mockMvc.perform(post("/api/admin/v1/operations/activities/{id}/items", activityId)
                .header("Authorization", bearer(token))
                .header("X-Region", region)
                .contentType(MediaType.APPLICATION_JSON)
                .content(body));
    }

    private List<String> readValues(MvcResult result, String fieldName) throws Exception {
        JsonNode data = objectMapper.readTree(result.getResponse().getContentAsByteArray()).path("data");
        List<String> values = new ArrayList<>();
        for (JsonNode item : data) {
            values.add(item.path(fieldName).asText());
        }
        return values;
    }

    private long readId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsByteArray()).at("/data/id").asLong();
    }

    private String createReadOnlyAdminAndLogin() throws Exception {
        jdbcTemplate.update("""
                INSERT INTO admin_role(code, name, description, status, built_in)
                VALUES('activity_reader_test', '活动只读测试', '', 1, FALSE)
                """);
        Long roleId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_role WHERE code='activity_reader_test'", Long.class);
        jdbcTemplate.update("""
                INSERT INTO admin_user(account, password_hash, name, status)
                SELECT 'activity-reader-test', password_hash, '活动只读测试', 1
                FROM admin_user WHERE id=1
                """);
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account='activity-reader-test'", Long.class);
        jdbcTemplate.update("INSERT INTO admin_user_role(admin_id, role_id) VALUES(?,?)", adminId, roleId);
        jdbcTemplate.update("""
                INSERT INTO admin_role_permission(role_id, permission_id)
                SELECT ?, id FROM admin_permission WHERE code='operations:activity:read'
                """, roleId);
        jdbcTemplate.update("INSERT INTO admin_region_scope(admin_id, region) VALUES(?, 'EU')", adminId);
        return loginToken("activity-reader-test");
    }

    private int count(String sql, long id) {
        return jdbcTemplate.queryForObject(sql, Integer.class, id);
    }

    private String loginToken(String account) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                .content("""
                                {
                                  "account": "%s",
                                  "password": "admin123456"
                                }
                                """.formatted(account)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsByteArray()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
