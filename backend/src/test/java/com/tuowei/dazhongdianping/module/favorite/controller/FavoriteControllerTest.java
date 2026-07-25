package com.tuowei.dazhongdianping.module.favorite.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class FavoriteControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRequireLogin() throws Exception {
        mockMvc.perform(get("/api/c/v1/favorites"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldFavoriteListAndRemoveShopIdempotently() throws Exception {
        String token = registerToken();
        String body = "{\"targetType\":1,\"targetId\":10001}";

        for (int index = 0; index < 2; index++) {
            mockMvc.perform(post("/api/c/v1/favorites")
                            .header("Authorization", bearer(token))
                            .header("X-Region", "CN")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(body))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.targetId").value(10001))
                    .andExpect(jsonPath("$.data.target.name").value("渝里火锅徐汇店"));
        }

        mockMvc.perform(get("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .param("targetType", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].target.id").value(10001));

        mockMvc.perform(delete("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .param("targetType", "1")
                        .param("targetId", "10001"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
    }

    @Test
    void shouldRejectCrossRegionAndMissingPostTarget() throws Exception {
        String token = registerToken();
        mockMvc.perform(post("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":1,\"targetId\":20001}"))
                .andExpect(status().isNotFound());

        mockMvc.perform(post("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":2,\"targetId\":1}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldFavoriteAndListPublicPosts() throws Exception {
        String token = registerToken();
        Long postId = insertPublicPost("CN", "收藏测试帖子");

        mockMvc.perform(post("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":2,\"targetId\":" + postId + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.targetType").value(2))
                .andExpect(jsonPath("$.data.targetTypeText").value("帖子"))
                .andExpect(jsonPath("$.data.targetId").value(postId.intValue()))
                .andExpect(jsonPath("$.data.target.name").value("收藏测试帖子"));

        mockMvc.perform(get("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .param("targetType", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].targetType").value(2))
                .andExpect(jsonPath("$.data.list[0].target.name").value("收藏测试帖子"));

        mockMvc.perform(get("/api/c/v1/favorites")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1));
    }

    private String registerToken() throws Exception {
        String account = "favorite-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account + "\",\"deviceId\":\"favorite-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\",\"nickname\":\"收藏测试\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private Long insertPublicPost(String region, String title) {
        jdbcTemplate.update("""
                INSERT INTO post(user_id,region,user_name,title,content,content_type,like_count,comment_count,
                                 audit_status,audit_remark,status,is_deleted)
                VALUES(1,?,?,?,'收藏联调内容',1,0,0,1,'',1,FALSE)
                """, region, "收藏作者", title);
        return jdbcTemplate.queryForObject("SELECT id FROM post WHERE title=?", Long.class, title);
    }

    private String bearer(String token) { return "Bearer " + token; }
}
