package com.tuowei.dazhongdianping.module.admin.hotword;

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
class AdminHotWordControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldCreateUpdateDisableDeleteHotWordsAndAffectPublicSearchHot() throws Exception {
        jdbcTemplate.update("UPDATE hot_keyword SET enabled=FALSE WHERE region='EU'");
        String token = loginToken("admin");

        long remoteId = readId(createHotWord(token, "EU", "Remote", 1)
                .andExpect(status().isOk())
                .andReturn());
        long breakfastId = readId(createHotWord(token, "EU", "Breakfast", 2)
                .andExpect(status().isOk())
                .andReturn());

        assertThat(readTerms(mockMvc.perform(get("/api/admin/v1/search/hotwords")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("Remote", "Breakfast");

        mockMvc.perform(get("/api/c/v1/search/hot")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].term").value("Remote"))
                .andExpect(jsonPath("$.data[0].score").value(2))
                .andExpect(jsonPath("$.data[1].term").value("Breakfast"))
                .andExpect(jsonPath("$.data[1].score").value(1));

        mockMvc.perform(put("/api/admin/v1/search/hotwords/{id}", remoteId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "keyword": "Remote Friendly",
                                  "sortNo": 3
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.keyword").value("Remote Friendly"))
                .andExpect(jsonPath("$.data.sortNo").value(3));

        assertThat(readTerms(mockMvc.perform(get("/api/c/v1/search/hot")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("Remote Friendly", "Breakfast")
                .doesNotContain("Remote");

        mockMvc.perform(put("/api/admin/v1/search/hotwords/{id}/status", remoteId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.enabled").value(false));

        assertThat(readTerms(mockMvc.perform(get("/api/c/v1/search/hot")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("Breakfast")
                .doesNotContain("Remote Friendly");

        mockMvc.perform(delete("/api/admin/v1/search/hotwords/{id}", breakfastId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        assertThat(readTerms(mockMvc.perform(get("/api/c/v1/search/hot")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn()))
                .contains("Cafe")
                .doesNotContain("Remote Friendly");
    }

    @Test
    void shouldRequireWritePermissionAndRejectDuplicateKeywordOrCrossRegionMutation() throws Exception {
        String readerToken = createReadOnlyAdminAndLogin();
        mockMvc.perform(get("/api/admin/v1/search/hotwords")
                        .header("Authorization", bearer(readerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        createHotWord(readerToken, "EU", "只读不该创建", 1)
                .andExpect(status().isForbidden());

        String token = loginToken("admin");
        createHotWord(token, "EU", "Cafe", 0)
                .andExpect(status().isConflict());

        long cnHotWordId = readId(createHotWord(token, "CN", "深夜食堂", 9)
                .andExpect(status().isOk())
                .andReturn());

        mockMvc.perform(put("/api/admin/v1/search/hotwords/{id}/status", cnHotWordId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldExposeHotWordPermissionsAndOperationsMenu() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:hotword:read')]").exists())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:hotword:write')]").exists())
                .andReturn();
        String token = objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[3].children[5].path").value("/operations/hotwords"));
    }

    private org.springframework.test.web.servlet.ResultActions createHotWord(String token,
                                                                            String region,
                                                                            String keyword,
                                                                            int sortNo) throws Exception {
        return mockMvc.perform(post("/api/admin/v1/search/hotwords")
                .header("Authorization", bearer(token))
                .header("X-Region", region)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "keyword": "%s",
                          "sortNo": %d
                        }
                        """.formatted(keyword, sortNo)));
    }

    private List<String> readTerms(MvcResult result) throws Exception {
        JsonNode data = objectMapper.readTree(result.getResponse().getContentAsString()).path("data");
        List<String> terms = new ArrayList<>();
        for (JsonNode item : data) {
            terms.add(item.path("term").asText(""));
            if (!item.path("keyword").asText("").isBlank()) {
                terms.remove(terms.size() - 1);
                terms.add(item.path("keyword").asText());
            }
        }
        return terms;
    }

    private long readId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private String createReadOnlyAdminAndLogin() throws Exception {
        jdbcTemplate.update("""
                INSERT INTO admin_role(code, name, description, status, built_in)
                VALUES('hotword_reader_test', '热词只读测试', '', 1, FALSE)
                """);
        Long roleId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_role WHERE code='hotword_reader_test'", Long.class);
        jdbcTemplate.update("""
                INSERT INTO admin_user(account, password_hash, name, status)
                SELECT 'hotword-reader-test', password_hash, '热词只读测试', 1
                FROM admin_user WHERE id=1
                """);
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account='hotword-reader-test'", Long.class);
        jdbcTemplate.update("INSERT INTO admin_user_role(admin_id, role_id) VALUES(?,?)", adminId, roleId);
        jdbcTemplate.update("""
                INSERT INTO admin_role_permission(role_id, permission_id)
                SELECT ?, id FROM admin_permission WHERE code='operations:hotword:read'
                """, roleId);
        jdbcTemplate.update("INSERT INTO admin_region_scope(admin_id, region) VALUES(?, 'EU')", adminId);
        return loginToken("hotword-reader-test");
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
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
