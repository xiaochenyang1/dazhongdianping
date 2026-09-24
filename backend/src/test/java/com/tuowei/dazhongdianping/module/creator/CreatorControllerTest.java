package com.tuowei.dazhongdianping.module.creator;

import static org.hamcrest.Matchers.hasItem;
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
class CreatorControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void claimOnceThenCompleteAwardsPointsOnce() throws Exception {
        Session user = registerUser();

        mockMvc.perform(get("/api/c/v1/creator/tasks").header("X-Region", "CN"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/api/c/v1/creator/tasks")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==9101)].claimStatus", hasItem(0)))
                .andExpect(jsonPath("$.data.list[?(@.id==9102)].id").doesNotExist());

        mockMvc.perform(get("/api/c/v1/creator/tasks")
                        .header("Authorization", bearer(user.token())).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==9102)].claimStatus", hasItem(0)))
                .andExpect(jsonPath("$.data.list[?(@.id==9101)].id").doesNotExist());

        mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/claim", 9102)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isNotFound());

        MvcResult claimed = mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/claim", 9101)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("creator.claimed"))
                .andExpect(jsonPath("$.data.claimStatus").value(1))
                .andReturn();
        long claimId = objectMapper.readTree(claimed.getResponse().getContentAsString()).at("/data/claimId").asLong();

        mockMvc.perform(get("/api/c/v1/creator/tasks")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(jsonPath("$.data.list[?(@.id==9101)].claimStatus", hasItem(1)));

        mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/claim", 9101)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isBadRequest());

        mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/complete", 9101)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("creator.completed"))
                .andExpect(jsonPath("$.data.claimStatus").value(2))
                .andExpect(jsonPath("$.data.rewardPoints").value(20))
                .andExpect(jsonPath("$.data.points").value(20));

        Integer points = jdbcTemplate.queryForObject(
                "SELECT points FROM app_user WHERE id = ?", Integer.class, user.userId());
        assertEquals(20, points);
        Number logs = jdbcTemplate.queryForObject(
                """
                SELECT COUNT(*) FROM growth_points_log
                WHERE user_id = ? AND type = 2 AND action = 'creator_task'
                  AND biz_id = ? AND change_amount = 20 AND balance_after = 20
                """,
                Number.class, user.userId(), claimId);
        assertEquals(1, logs.intValue());

        mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/complete", 9101)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isBadRequest());
        Number logsAfter = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM growth_points_log WHERE user_id = ? AND action = 'creator_task'",
                Number.class, user.userId());
        assertEquals(1, logsAfter.intValue());
        mockMvc.perform(get("/api/c/v1/creator/tasks")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(jsonPath("$.data.list[?(@.id==9101)].claimStatus", hasItem(2)));
    }

    @Test
    void completeRequiresClaimAndAdminCanSaveTask() throws Exception {
        Session user = registerUser();
        mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/complete", 9101)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isBadRequest());

        String admin = adminLogin();
        MvcResult created = mockMvc.perform(post("/api/admin/v1/creator/tasks")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"补一张菜单图","description":"再写一段","rewardPoints":5,"status":1}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.creator_saved"))
                .andExpect(jsonPath("$.data.rewardPoints").value(5))
                .andReturn();
        long taskId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(put("/api/admin/v1/creator/tasks/{id}", taskId)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"title":"补一张菜单图","description":"改说明","rewardPoints":8,"status":1}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.creator_saved"))
                .andExpect(jsonPath("$.data.rewardPoints").value(8));

        mockMvc.perform(get("/api/admin/v1/creator/tasks")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + taskId + ")].rewardPoints", hasItem(8)))
                .andExpect(jsonPath("$.data.list[?(@.id==9101)].id").exists());

        mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/claim", taskId)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("creator.claimed"));
        mockMvc.perform(post("/api/c/v1/creator/tasks/{id}/complete", taskId)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.points").value(8));
    }

    private Session registerUser() throws Exception {
        String account = "creator-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"creator-" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        JsonNode data = objectMapper.readTree(result.getResponse().getContentAsString()).at("/data");
        return new Session(data.at("/accessToken").asText(), data.at("/user/id").asLong());
    }

    private String adminLogin() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record Session(String token, long userId) {
    }
}
