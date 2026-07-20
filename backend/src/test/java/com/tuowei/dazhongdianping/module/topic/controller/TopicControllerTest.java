package com.tuowei.dazhongdianping.module.topic.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
class TopicControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldListCurrentRegionTopicsAndExposeOptionalFollowState() throws Exception {
        long euTopic = insertTopic("EU", "伦敦咖啡", 1, true, 0, null);
        long cnTopic = insertTopic("CN", "上海咖啡", 1, true, 0, null);
        UserAccess user = registerUser("话题关注者");

        mockMvc.perform(get("/api/c/v1/topics")
                        .param("sort", "recommended")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(euTopic))
                .andExpect(jsonPath("$.data.list[0].name").value("伦敦咖啡"))
                .andExpect(jsonPath("$.data.list[0].followedByCurrentUser").value(false));

        mockMvc.perform(get("/api/c/v1/topics/{id}", cnTopic).header("X-Region", "EU"))
                .andExpect(status().isNotFound());

        mockMvc.perform(put("/api/c/v1/topics/{id}/follow", euTopic)
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.topicId").value(euTopic))
                .andExpect(jsonPath("$.data.followed").value(true))
                .andExpect(jsonPath("$.data.followerCount").value(1));

        mockMvc.perform(put("/api/c/v1/topics/{id}/follow", euTopic)
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.followerCount").value(1));

        mockMvc.perform(get("/api/c/v1/topics/{id}", euTopic)
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.followedByCurrentUser").value(true))
                .andExpect(jsonPath("$.data.followerCount").value(1));

        mockMvc.perform(get("/api/c/v1/topics/following")
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(euTopic));

        mockMvc.perform(delete("/api/c/v1/topics/{id}/follow", euTopic)
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.followed").value(false))
                .andExpect(jsonPath("$.data.followerCount").value(0));

        mockMvc.perform(delete("/api/c/v1/topics/{id}/follow", euTopic)
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.followerCount").value(0));
    }

    @Test
    void shouldRequireLoginOnlyForFollowingAndWriteOperations() throws Exception {
        long topicId = insertTopic("EU", "欧洲生活", 1, false, 0, null);

        mockMvc.perform(get("/api/c/v1/topics").header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/c/v1/topics/{id}", topicId).header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/c/v1/topics/{id}/posts", topicId).header("X-Region", "EU"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/topics/following").header("X-Region", "EU"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(put("/api/c/v1/topics/{id}/follow", topicId).header("X-Region", "EU"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldHideBlockedMergedAndCrossRegionTopics() throws Exception {
        long target = insertTopic("EU", "英国咖啡", 1, false, 0, null);
        long blocked = insertTopic("EU", "禁用话题", 2, false, 0, null);
        long merged = insertTopic("EU", "伦敦咖啡旧名", 2, false, 0, target);
        long cnTopic = insertTopic("CN", "北京咖啡", 1, false, 0, null);
        UserAccess user = registerUser("不可见话题测试");

        for (long topicId : new long[]{blocked, merged, cnTopic}) {
            mockMvc.perform(get("/api/c/v1/topics/{id}", topicId).header("X-Region", "EU"))
                    .andExpect(status().isNotFound());
            mockMvc.perform(put("/api/c/v1/topics/{id}/follow", topicId)
                            .header("Authorization", bearer(user.token()))
                            .header("X-Region", "EU"))
                    .andExpect(status().isNotFound());
        }
    }

    @Test
    void shouldAutoCreateNormalizeRedirectAndReplacePostTopics() throws Exception {
        UserAccess user = registerUser("话题作者");
        long target = insertTopic("EU", "英国咖啡", 1, false, 0, null);
        insertTopic("EU", "伦敦咖啡", 2, false, 0, target);

        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title":"伦敦咖啡地图",
                                  "content":"本周新增三家咖啡店。",
                                  "contentType":1,
                                  "images":[],
                                  "topics":[" 伦敦咖啡 ","伦敦咖啡","新开店"]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.topics[0]").value("英国咖啡"))
                .andExpect(jsonPath("$.data.topics[1]").value("新开店"))
                .andReturn();
        long postId = readLong(created, "/data/id");

        long newTopicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topic WHERE region='EU' AND name='新开店'",
                Long.class
        );
        Integer targetLinks = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM post_topic WHERE post_id=? AND topic_id=?",
                Integer.class,
                postId,
                target
        );
        Integer newLinks = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM post_topic WHERE post_id=? AND topic_id=?",
                Integer.class,
                postId,
                newTopicId
        );
        org.assertj.core.api.Assertions.assertThat(targetLinks).isEqualTo(1);
        org.assertj.core.api.Assertions.assertThat(newLinks).isEqualTo(1);

        mockMvc.perform(put("/api/c/v1/posts/{id}", postId)
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title":"伦敦咖啡地图更新",
                                  "content":"改为只保留周末市集话题。",
                                  "contentType":1,
                                  "images":[],
                                  "topics":["周末市集"]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.topics.length()").value(1))
                .andExpect(jsonPath("$.data.topics[0]").value("周末市集"));

        Integer remainingOldLinks = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM post_topic WHERE post_id=? AND topic_id IN (?,?)",
                Integer.class,
                postId,
                target,
                newTopicId
        );
        org.assertj.core.api.Assertions.assertThat(remainingOldLinks).isZero();
    }

    @Test
    void shouldRejectBlockedTopicNameWithoutRecreatingIt() throws Exception {
        UserAccess user = registerUser("屏蔽话题作者");
        insertTopic("EU", "不可发布", 2, false, 0, null);

        mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(user.token()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title":"屏蔽话题测试",
                                  "content":"不能绕过运营屏蔽。",
                                  "contentType":1,
                                  "images":[],
                                  "topics":["不可发布"]
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("话题不可用"));

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM topic WHERE region='EU' AND name='不可发布'",
                Integer.class
        );
        org.assertj.core.api.Assertions.assertThat(count).isEqualTo(1);
    }

    private long insertTopic(String region, String name, int status, boolean recommended,
                             int pinnedSort, Long mergedToId) {
        jdbcTemplate.update("""
                INSERT INTO topic(region,name,post_count,follower_count,recommended,pinned_sort,merged_to_id,status)
                VALUES(?,?,0,0,?,?,?,?)
                """, region, name, recommended, pinnedSort, mergedToId, status);
        return jdbcTemplate.queryForObject(
                "SELECT id FROM topic WHERE region=? AND name=?",
                Long.class,
                region,
                name
        );
    }

    private UserAccess registerUser(String nickname) throws Exception {
        String account = "topic-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> {
                            request.setRemoteAddr("10.99.17.8");
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scene":"register","type":"email","account":"%s","deviceId":"topic-test-%s"}
                                """.formatted(account, UUID.randomUUID())))
                .andExpect(status().isOk());
        MvcResult registered = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"%s","code":"123456","password":"Passw0rd!","nickname":"%s","preferredRegion":"EU"}
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andReturn();
        String token = readText(registered, "/data/accessToken");
        MvcResult me = mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn();
        return new UserAccess(readLong(me, "/data/id"), token);
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }

    private long readLong(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asLong();
    }

    private record UserAccess(long id, String token) {}
}
