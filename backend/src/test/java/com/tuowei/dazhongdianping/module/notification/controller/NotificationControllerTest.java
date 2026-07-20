package com.tuowei.dazhongdianping.module.notification.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
class NotificationControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRequireLoginForNotificationApis() throws Exception {
        mockMvc.perform(get("/api/c/v1/notifications"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/c/v1/ws/ticket"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldListUnreadNotificationAndAckIt() throws Exception {
        RegisteredUser user = registerUser();
        jdbcTemplate.update("""
                INSERT INTO user_notification(user_id, region, type, title, content, link_url, is_read)
                VALUES (?, 'CN', 'review.reply', '商家回复了你的点评', '谢谢你的支持', '/reviews/1', FALSE)
                """, user.userId());

        MvcResult listResult = mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].type").value("review.reply"))
                .andExpect(jsonPath("$.data.list[0].read").value(false))
                .andReturn();
        long notificationId = objectMapper.readTree(listResult.getResponse().getContentAsString())
                .at("/data/list/0/id").asLong();

        mockMvc.perform(get("/api/c/v1/notifications/unread-count")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(1));

        mockMvc.perform(post("/api/c/v1/notifications/{id}/ack", notificationId)
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.read").value(true));

        mockMvc.perform(get("/api/c/v1/notifications/unread-count")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(0));
    }

    @Test
    void shouldIssueSingleUseWebSocketTicket() throws Exception {
        RegisteredUser user = registerUser();
        mockMvc.perform(post("/api/c/v1/ws/ticket")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.ticket").isNotEmpty())
                .andExpect(jsonPath("$.data.expiresInSeconds").value(60));
    }

    private RegisteredUser registerUser() throws Exception {
        String account = "notification-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account + "\",\"deviceId\":\"notification-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\",\"nickname\":\"通知测试\"}"))
                .andExpect(status().isOk()).andReturn();
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return new RegisteredUser(root.at("/data/user/id").asLong(), root.at("/data/accessToken").asText());
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record RegisteredUser(long userId, String accessToken) {}
}
