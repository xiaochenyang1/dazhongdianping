package com.tuowei.dazhongdianping.module.admin.banner;

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
class AdminBannerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldCreateUpdateDisableDeleteBannersAndAffectPublicHome() throws Exception {
        String token = loginToken("admin");
        long cityBannerId = readId(createBanner(
                token,
                "EU",
                "Paris Exclusive Banner",
                101L,
                "Only for Paris home",
                "/shops?cityId=101&areaId=1011",
                3
        ).andExpect(status().isOk()).andReturn());
        long globalBannerId = readId(createBanner(
                token,
                "EU",
                "EU Shared Banner",
                null,
                "Visible across EU home pages",
                "/shops?cityId=101",
                4
        ).andExpect(status().isOk()).andReturn());

        assertThat(readTitles(mockMvc.perform(get("/api/admin/v1/banners")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("cityId", "101"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("Paris Exclusive Banner", "EU Shared Banner");

        assertThat(readTitles(mockMvc.perform(get("/api/c/v1/home/banners")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("EU Shared Banner")
                .doesNotContain("Paris Exclusive Banner");

        assertThat(readTitles(mockMvc.perform(get("/api/c/v1/home/banners")
                        .header("X-Region", "EU")
                        .param("cityId", "101"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("Paris Exclusive Banner", "EU Shared Banner");

        mockMvc.perform(put("/api/admin/v1/banners/{id}", cityBannerId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "cityId": 101,
                                  "title": "Paris Exclusive Banner Updated",
                                  "subtitle": "Only for Paris home",
                                  "imageUrl": "https://placehold.co/1440x560/0f766e/ffffff?text=Paris+Exclusive+Banner",
                                  "linkUrl": "/shops?cityId=101&areaId=1011",
                                  "sortNo": 7
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Paris Exclusive Banner Updated"))
                .andExpect(jsonPath("$.data.sortNo").value(7));

        mockMvc.perform(put("/api/admin/v1/banners/{id}/status", cityBannerId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.enabled").value(false));

        assertThat(readTitles(mockMvc.perform(get("/api/c/v1/home/banners")
                        .header("X-Region", "EU")
                        .param("cityId", "101"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("EU Shared Banner")
                .doesNotContain("Paris Exclusive Banner Updated");

        mockMvc.perform(delete("/api/admin/v1/banners/{id}", globalBannerId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        assertThat(readTitles(mockMvc.perform(get("/api/admin/v1/banners")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn()))
                .doesNotContain("EU Shared Banner");

        assertThat(readTitles(mockMvc.perform(get("/api/c/v1/home/banners")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn()))
                .doesNotContain("EU Shared Banner");
    }

    @Test
    void shouldRequireWritePermissionAndRejectInvalidCityOrCrossRegionMutation() throws Exception {
        String readerToken = createReadOnlyAdminAndLogin();
        mockMvc.perform(get("/api/admin/v1/banners")
                        .header("Authorization", bearer(readerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        createBanner(
                readerToken,
                "EU",
                "只读不该创建",
                null,
                "不会成功",
                "/shops?cityId=101",
                1
        ).andExpect(status().isForbidden());

        String token = loginToken("admin");
        createBanner(
                token,
                "EU",
                "Invalid City Banner",
                1L,
                "Cross-region city",
                "/shops?cityId=101",
                1
        ).andExpect(status().isConflict());

        long cnBannerId = readId(createBanner(
                token,
                "CN",
                "Shanghai Banner",
                1L,
                "Only for CN",
                "/shops?cityId=1",
                2
        ).andExpect(status().isOk()).andReturn());

        mockMvc.perform(put("/api/admin/v1/banners/{id}/status", cnBannerId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldExposeBannerPermissionsAndOperationsMenu() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:banner:read')]").exists())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:banner:write')]").exists())
                .andReturn();
        String token = objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[3].children[4].path").value("/operations/banners"));
    }

    private org.springframework.test.web.servlet.ResultActions createBanner(String token,
                                                                           String region,
                                                                           String title,
                                                                           Long cityId,
                                                                           String subtitle,
                                                                           String linkUrl,
                                                                           int sortNo) throws Exception {
        String cityPart = cityId == null ? "null" : cityId.toString();
        return mockMvc.perform(post("/api/admin/v1/banners")
                .header("Authorization", bearer(token))
                .header("X-Region", region)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "cityId": %s,
                          "title": "%s",
                          "subtitle": "%s",
                          "imageUrl": "https://placehold.co/1440x560/2563eb/ffffff?text=Banner",
                          "linkUrl": "%s",
                          "sortNo": %d
                        }
                        """.formatted(cityPart, title, subtitle, linkUrl, sortNo)));
    }

    private List<String> readTitles(MvcResult result) throws Exception {
        JsonNode data = objectMapper.readTree(result.getResponse().getContentAsString()).path("data");
        List<String> titles = new ArrayList<>();
        for (JsonNode item : data) {
            titles.add(item.path("title").asText());
        }
        return titles;
    }

    private long readId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private String createReadOnlyAdminAndLogin() throws Exception {
        jdbcTemplate.update("""
                INSERT INTO admin_role(code, name, description, status, built_in)
                VALUES('banner_reader_test', 'Banner 只读测试', '', 1, FALSE)
                """);
        Long roleId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_role WHERE code='banner_reader_test'", Long.class);
        jdbcTemplate.update("""
                INSERT INTO admin_user(account, password_hash, name, status)
                SELECT 'banner-reader-test', password_hash, 'Banner 只读测试', 1
                FROM admin_user WHERE id=1
                """);
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account='banner-reader-test'", Long.class);
        jdbcTemplate.update("INSERT INTO admin_user_role(admin_id, role_id) VALUES(?,?)", adminId, roleId);
        jdbcTemplate.update("""
                INSERT INTO admin_role_permission(role_id, permission_id)
                SELECT ?, id FROM admin_permission WHERE code='operations:banner:read'
                """, roleId);
        jdbcTemplate.update("INSERT INTO admin_region_scope(admin_id, region) VALUES(?, 'EU')", adminId);
        return loginToken("banner-reader-test");
    }

    private String loginToken(String account) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
