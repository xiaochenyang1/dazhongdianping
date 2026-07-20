package com.tuowei.dazhongdianping.module.social.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.sql.Timestamp;
import java.time.LocalDateTime;
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
class SocialControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldFollowAndUnfollowIdempotentlyAcrossRegions() throws Exception {
        UserAccess follower = registerUser("关注者");
        UserAccess followed = registerUser("被关注者");

        mockMvc.perform(put("/api/c/v1/follow/{userId}", followed.id())
                        .header("Authorization", bearer(follower.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.userId").value(followed.id()))
                .andExpect(jsonPath("$.data.following").value(true))
                .andExpect(jsonPath("$.data.followerCount").value(1));

        MvcResult notificationResult = mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(followed.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].type").value("social.follow"))
                .andExpect(jsonPath("$.data.list[0].actorUserId").value(follower.id()))
                .andExpect(jsonPath("$.data.list[0].read").value(false))
                .andReturn();
        long notificationId = readLong(notificationResult, "/data/list/0/id");
        mockMvc.perform(post("/api/c/v1/notifications/{id}/ack", notificationId)
                        .header("Authorization", bearer(followed.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.read").value(true));
        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(followed.token())).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].read").value(true));

        mockMvc.perform(put("/api/c/v1/follow/{userId}", followed.id())
                        .header("Authorization", bearer(follower.token()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.followerCount").value(1));

        mockMvc.perform(get("/api/c/v1/user/{userId}/followers", followed.id())
                        .header("Authorization", bearer(follower.token()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(follower.id()))
                .andExpect(jsonPath("$.data.list[0].followedByCurrentUser").value(false));

        mockMvc.perform(get("/api/c/v1/user/{userId}/following", follower.id())
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(followed.id()));

        mockMvc.perform(delete("/api/c/v1/follow/{userId}", followed.id())
                        .header("Authorization", bearer(follower.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.following").value(false))
                .andExpect(jsonPath("$.data.followerCount").value(0));

        mockMvc.perform(delete("/api/c/v1/follow/{userId}", followed.id())
                        .header("Authorization", bearer(follower.token()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.followerCount").value(0));
    }

    @Test
    void shouldRejectSelfFollowAndMissingTarget() throws Exception {
        UserAccess user = registerUser("自关注测试");

        mockMvc.perform(put("/api/c/v1/follow/{userId}", user.id())
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isBadRequest());

        mockMvc.perform(put("/api/c/v1/follow/{userId}", 99999999L)
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldExposeProfileCountsAndFilterFollowingFeedByRegion() throws Exception {
        UserAccess follower = registerUser("关注流读者");
        UserAccess followed = registerUser("关注流作者");
        mockMvc.perform(put("/api/c/v1/follow/{userId}", followed.id())
                        .header("Authorization", bearer(follower.token())).header("X-Region", "EU"))
                .andExpect(status().isOk());

        insertPost(99001L, followed.id(), "EU", "欧洲公开帖", 1, 1, false);
        insertPost(99002L, followed.id(), "CN", "中国公开帖", 1, 1, false);
        insertPost(99003L, followed.id(), "EU", "欧洲待审帖", 0, 1, false);
        insertPost(99004L, followed.id(), "EU", "欧洲已删除帖", 1, 1, true);

        mockMvc.perform(get("/api/c/v1/user/{userId}", followed.id())
                        .header("Authorization", bearer(follower.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.followerCount").value(1))
                .andExpect(jsonPath("$.data.followingCount").value(0))
                .andExpect(jsonPath("$.data.followedByCurrentUser").value(true));

        mockMvc.perform(get("/api/c/v1/posts/following")
                        .header("Authorization", bearer(follower.token())).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(99001L));

        mockMvc.perform(get("/api/c/v1/posts/following")
                        .header("Authorization", bearer(follower.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(99002L));
    }

    private UserAccess registerUser(String nickname) throws Exception {
        String account = "social-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> { request.setRemoteAddr("10.78.12.9"); return request; })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scene":"register","type":"email","account":"%s","deviceId":"social-test"}
                                """.formatted(account)))
                .andExpect(status().isOk());
        MvcResult register = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"%s","code":"123456","password":"Passw0rd!","nickname":"%s","preferredRegion":"EU"}
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andReturn();
        String token = readText(register, "/data/accessToken");
        MvcResult me = mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn();
        return new UserAccess(readLong(me, "/data/id"), token);
    }

    private String bearer(String token) { return "Bearer " + token; }
    private void insertPost(long id, long userId, String region, String title, int auditStatus, int status, boolean deleted) {
        jdbcTemplate.update("""
                INSERT INTO post(id,user_id,region,user_name,title,content,content_type,like_count,comment_count,
                                 audit_status,audit_remark,status,is_deleted,created_at,updated_at)
                VALUES(?,?,?,?,?,'测试内容',1,0,0,?,'',?,?,?,?)
                """, id, userId, region, "关注流作者", title, auditStatus, status, deleted,
                Timestamp.valueOf(LocalDateTime.now()), Timestamp.valueOf(LocalDateTime.now()));
    }
    private String readText(MvcResult result, String pointer) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at(pointer).asText();
    }
    private long readLong(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asLong();
    }
    private record UserAccess(long id, String token) {}
}
