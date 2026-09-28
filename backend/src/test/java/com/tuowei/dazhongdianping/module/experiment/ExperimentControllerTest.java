package com.tuowei.dazhongdianping.module.experiment;

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
class ExperimentControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void flagsFollowRolloutAndStayInRegion() throws Exception {
        mockMvc.perform(get("/api/c/v1/flags").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.flagKey=='guide_home')].enabled", hasItem(true)));
        mockMvc.perform(get("/api/c/v1/flags").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.flagKey=='guide_home')].enabled", hasItem(true)));

        String admin = adminLogin();
        long zero = createFlag(admin, "CN", "rollout_zero", true, 0);
        long full = createFlag(admin, "CN", "rollout_full", true, 100);
        long off = createFlag(admin, "CN", "rollout_off", false, 100);
        createFlag(admin, "CN", "rollout_half", true, 50);
        createFlag(admin, "EU", "eu_only", true, 100);

        boolean half = Math.floorMod(Math.abs("rollout_half".hashCode()), 100) < 50;
        mockMvc.perform(get("/api/c/v1/flags").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.flagKey=='rollout_zero')].enabled", hasItem(false)))
                .andExpect(jsonPath("$.data[?(@.flagKey=='rollout_full')].enabled", hasItem(true)))
                .andExpect(jsonPath("$.data[?(@.flagKey=='rollout_off')].enabled", hasItem(false)))
                .andExpect(jsonPath("$.data[?(@.flagKey=='rollout_half')].enabled", hasItem(half)))
                .andExpect(jsonPath("$.data[?(@.flagKey=='eu_only')].flagKey").doesNotExist());

        mockMvc.perform(put("/api/admin/v1/flags/{id}", full)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"flagKey":"rollout_full","description":"关掉","enabled":true,"rolloutPercent":0}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.flag_saved"))
                .andExpect(jsonPath("$.data.rolloutPercent").value(0));
        mockMvc.perform(get("/api/c/v1/flags").header("X-Region", "CN"))
                .andExpect(jsonPath("$.data[?(@.flagKey=='rollout_full')].enabled", hasItem(false)));

        mockMvc.perform(post("/api/admin/v1/flags")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"flagKey":"guide_home","description":"重复","enabled":true,"rolloutPercent":100}
                                """))
                .andExpect(status().isBadRequest());

        mockMvc.perform(get("/api/admin/v1/flags")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + zero + ")].flagKey", hasItem("rollout_zero")));
        // keep off referenced so a future assertion can target the id
        assertEquals("rollout_off", jdbcTemplate.queryForObject(
                "SELECT flag_key FROM feature_flag WHERE id = ?", String.class, off));
    }

    @Test
    void assignmentIsStickyForRunningExperiment() throws Exception {
        String admin = adminLogin();
        Session user = registerUser();
        MvcResult created = mockMvc.perform(post("/api/admin/v1/experiments")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"首页攻略实验\",\"flagKey\":\"guide_home\",\"status\":1}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.experiment_saved"))
                .andReturn();
        long experimentId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/admin/v1/experiments")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + experimentId + ")].status", hasItem(1)));

        mockMvc.perform(post("/api/c/v1/experiments/{id}/assign", experimentId)
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"variant\":\"A\"}"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/c/v1/experiments/{id}/assign", experimentId)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"variant\":\"A\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("experiment.assigned"))
                .andExpect(jsonPath("$.data.variant").value("A"));

        mockMvc.perform(post("/api/c/v1/experiments/{id}/assign", experimentId)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"variant\":\"B\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("experiment.assigned"))
                .andExpect(jsonPath("$.data.variant").value("A"));

        Number rows = jdbcTemplate.queryForObject(
                """
                SELECT COUNT(*) FROM experiment_assignment
                WHERE experiment_id = ? AND user_id = ? AND variant = 'A'
                """,
                Number.class, experimentId, user.userId());
        assertEquals(1, rows.intValue());

        mockMvc.perform(post("/api/c/v1/experiments/{id}/assign", experimentId)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"variant\":\"C\"}"))
                .andExpect(status().isBadRequest());

        MvcResult paused = mockMvc.perform(post("/api/admin/v1/experiments")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"暂停实验\",\"flagKey\":\"guide_home\",\"status\":0}"))
                .andExpect(status().isOk()).andReturn();
        long pausedId = objectMapper.readTree(paused.getResponse().getContentAsString()).at("/data/id").asLong();
        mockMvc.perform(post("/api/c/v1/experiments/{id}/assign", pausedId)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"variant\":\"A\"}"))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/c/v1/experiments/{id}/assign", 99999999L)
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"variant\":\"B\"}"))
                .andExpect(status().isNotFound());
    }

    private long createFlag(String admin, String region, String key, boolean enabled, int rollout) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/flags")
                        .header("Authorization", bearer(admin)).header("X-Region", region)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"flagKey":"%s","description":"%s","enabled":%s,"rolloutPercent":%d}
                                """.formatted(key, key, enabled, rollout)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.flag_saved"))
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private Session registerUser() throws Exception {
        String account = "exp-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"exp-" + UUID.randomUUID() + "\"}"))
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
