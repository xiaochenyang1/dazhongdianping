package com.tuowei.dazhongdianping.module.admin.sensitiveword;

import static org.hamcrest.Matchers.containsString;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminSensitiveWordControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldManageSensitiveWordsAndBlockReviewContent() throws Exception {
        String adminToken = loginAdmin("admin");
        String uniqueWord = "SW-" + UUID.randomUUID().toString().substring(0, 8);

        MvcResult created = mockMvc.perform(post("/api/admin/v1/operations/sensitive-words")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"word\":\"" + uniqueWord + "\",\"remark\":\"联调拦截\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.word").value(uniqueWord))
                .andExpect(jsonPath("$.data.enabled").value(true))
                .andReturn();
        long wordId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/admin/v1/operations/sensitive-words")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + wordId + ")].word").value(uniqueWord));

        String userToken = registerUser();
        String blockedContent = "这家店包含 " + uniqueWord + " 不能过";
        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewBody(blockedContent)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value(containsString(uniqueWord)));

        mockMvc.perform(put("/api/admin/v1/operations/sensitive-words/{id}/status", wordId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.enabled").value(false));

        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewBody(blockedContent)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value(blockedContent));

        mockMvc.perform(delete("/api/admin/v1/operations/sensitive-words/{id}", wordId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk());

        Integer remains = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM sensitive_word WHERE id=?",
                Integer.class,
                wordId
        );
        assertEquals(0, remains);
    }

    private String reviewBody(String content) {
        return "{"
                + "\"shopId\":10001,"
                + "\"content\":\"" + content + "\","
                + "\"scoreOverall\":4.5,"
                + "\"scoreTaste\":4.5,"
                + "\"scoreEnv\":4.0,"
                + "\"scoreService\":4.0,"
                + "\"cost\":88.00,"
                + "\"currency\":\"CNY\","
                + "\"tags\":[\"测试\"],"
                + "\"images\":[]"
                + "}";
    }

    private String loginAdmin(String account) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String registerUser() throws Exception {
        String account = "sw-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"sw-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
