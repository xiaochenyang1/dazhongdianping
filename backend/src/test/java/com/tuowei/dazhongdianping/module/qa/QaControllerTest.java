package com.tuowei.dazhongdianping.module.qa;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class QaControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void askAnswerAndBrowse() throws Exception {
        String asker = registerUser();

        // 提问。
        MvcResult asked = mockMvc.perform(post("/api/c/v1/shops/{shopId}/questions", 10001)
                        .header("Authorization", bearer(asker)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"周末需要预约吗？\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("qa.question_created"))
                .andReturn();
        long questionId = objectMapper.readTree(asked.getResponse().getContentAsString()).at("/data/id").asLong();

        // 游客可读到问题。
        mockMvc.perform(get("/api/c/v1/shops/{shopId}/questions", 10001).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + questionId + ")]").exists());

        // 另一位用户回答。
        String answerer = registerUser();
        mockMvc.perform(post("/api/c/v1/shops/{shopId}/questions/{qid}/answers", 10001, questionId)
                        .header("Authorization", bearer(answerer)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"周末建议提前预约。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("qa.answer_created"));

        // 回答数 +1，游客可读回答。
        mockMvc.perform(get("/api/c/v1/shops/{shopId}/questions", 10001).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + questionId + ")].answerCount").value(org.hamcrest.Matchers.hasItem(1)));

        mockMvc.perform(get("/api/c/v1/shops/{shopId}/questions/{qid}/answers", 10001, questionId)
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].content").value("周末建议提前预约。"));
    }

    @Test
    void askRequiresLogin() throws Exception {
        mockMvc.perform(post("/api/c/v1/shops/{shopId}/questions", 10001)
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"匿名提问\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void askRejectsUnknownShop() throws Exception {
        String user = registerUser();
        mockMvc.perform(post("/api/c/v1/shops/{shopId}/questions", 99999999L)
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"这家店存在吗？\"}"))
                .andExpect(status().isNotFound());
    }

    private String registerUser() throws Exception {
        String account = "qa-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"qa-test\"}"))
                .andExpect(status().isOk());
        MvcResult r = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(r.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
