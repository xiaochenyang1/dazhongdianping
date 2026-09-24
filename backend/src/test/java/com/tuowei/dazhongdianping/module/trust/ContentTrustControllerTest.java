package com.tuowei.dazhongdianping.module.trust;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
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
class ContentTrustControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void helpfulToggleIncrementsThenDecrements() throws Exception {
        String user = registerUser();

        mockMvc.perform(post("/api/c/v1/reviews/{id}/helpful", 1)
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("review.helpful_toggled"))
                .andExpect(jsonPath("$.data.voted").value(true))
                .andExpect(jsonPath("$.data.helpfulCount").value(1));

        mockMvc.perform(get("/api/c/v1/reviews/{id}", 1).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.helpfulCount").value(1));

        mockMvc.perform(get("/api/c/v1/shops/{shopId}/reviews", 10001)
                        .header("X-Region", "CN")
                        .param("sort", "helpful"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(1))
                .andExpect(jsonPath("$.data.list[0].helpfulCount").value(1));

        mockMvc.perform(post("/api/c/v1/reviews/{id}/helpful", 1)
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.voted").value(false))
                .andExpect(jsonPath("$.data.helpfulCount").value(0));
    }

    @Test
    void translationUpsert() throws Exception {
        String user = registerUser();

        mockMvc.perform(post("/api/c/v1/reviews/{id}/translations", 1)
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetLang\":\"en\",\"content\":\"Steady hotpot.\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("review.translation_saved"))
                .andExpect(jsonPath("$.data.targetLang").value("en"))
                .andExpect(jsonPath("$.data.content").value("Steady hotpot."));

        mockMvc.perform(post("/api/c/v1/reviews/{id}/translations", 1)
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetLang\":\"EN\",\"content\":\"Updated hotpot.\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("Updated hotpot."));

        mockMvc.perform(get("/api/c/v1/reviews/{id}/translations", 1)
                        .header("X-Region", "CN")
                        .param("lang", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].content").value("Updated hotpot."));
    }

    @Test
    void dishReview() throws Exception {
        String user = registerUser();

        mockMvc.perform(post("/api/c/v1/shops/{shopId}/dishes/{dishId}/reviews", 10001, 1)
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"score\":5,\"content\":\"毛肚很脆\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("dishreview.created"))
                .andExpect(jsonPath("$.data.score").value(5))
                .andExpect(jsonPath("$.data.content").value("毛肚很脆"));

        mockMvc.perform(get("/api/c/v1/shops/{shopId}/dishes/{dishId}/reviews", 10001, 1)
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].content").value("毛肚很脆"));

        mockMvc.perform(post("/api/c/v1/shops/{shopId}/dishes/{dishId}/reviews", 10001, 999999)
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"score\":4,\"content\":\"不存在\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void levelPrivilegesForNewUser() throws Exception {
        String user = registerUser();
        mockMvc.perform(get("/api/c/v1/user/level-privileges")
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.level").value(1))
                .andExpect(jsonPath("$.data.levelName").value("新手"))
                .andExpect(jsonPath("$.data.growthValue").value(0))
                .andExpect(jsonPath("$.data.privileges.badge").value("新手"));
    }

    @Test
    void chineseServiceFilterAndAmenities() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops")
                        .header("X-Region", "CN")
                        .param("chineseService", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[*].id", hasItem(10001)))
                .andExpect(jsonPath("$.data.list[*].id", not(hasItem(10002))));

        mockMvc.perform(get("/api/c/v1/shops/{id}/amenities", 10001).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.chineseService").value(true))
                .andExpect(jsonPath("$.data.chineseMenu").value(true))
                .andExpect(jsonPath("$.data.acceptAlipay").value(true))
                .andExpect(jsonPath("$.data.acceptWechat").value(true));

        mockMvc.perform(get("/api/c/v1/shops/{id}/amenities", 99999999).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
    }

    @Test
    void automodBlocksBannedReviewAndNormalReviewStillWorks() throws Exception {
        String user = registerUser();
        String admin = adminToken();

        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001, "这里有违禁演示词")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("内容未通过机审")))
                .andExpect(jsonPath("$.message", containsString("违禁演示词")));

        mockMvc.perform(get("/api/admin/v1/automod/hits")
                        .header("Authorization", bearer(admin))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].bizType").value("review"))
                .andExpect(jsonPath("$.data.list[0].decision").value(3))
                .andExpect(jsonPath("$.data.list[0].reason", containsString("违禁演示词")));

        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(user))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001, "锅底很稳，适合朋友聚餐。")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("review.created"));
    }

    private String reviewPayload(long shopId, String content) {
        return """
                {
                  "shopId": %d,
                  "content": "%s",
                  "scoreOverall": 5,
                  "scoreTaste": 5,
                  "scoreEnv": 5,
                  "scoreService": 5,
                  "cost": 20.00,
                  "currency": "CNY"
                }
                """.formatted(shopId, content);
    }

    private String registerUser() throws Exception {
        String account = "trust-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"trust-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
