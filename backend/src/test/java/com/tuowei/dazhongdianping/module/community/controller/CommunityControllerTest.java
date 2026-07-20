package com.tuowei.dazhongdianping.module.community.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
class CommunityControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldKeepNewPostPrivateUntilAdminPassesAudit() throws Exception {
        String userToken = registerUser();

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "伦敦周末早午餐避坑指南",
                                  "content": "排队超过四十分钟的不一定好吃，先看菜单和预约规则。",
                                  "contentType": 1,
                                  "images": ["https://files.example/community/brunch.jpg"],
                                  "topics": ["伦敦生活", "周末去哪"]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.auditStatus").value(0))
                .andExpect(jsonPath("$.data.images[0]").value("https://files.example/community/brunch.jpg"))
                .andExpect(jsonPath("$.data.topics[0]").value("伦敦生活"))
                .andReturn();
        long postId = readLong(createResult, "/data/id");

        mockMvc.perform(get("/api/c/v1/user/posts")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(postId));

        mockMvc.perform(get("/api/c/v1/posts/{postId}", postId)
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/c/v1/posts").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));

        long taskId = jdbcTemplate.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=4 AND biz_id=? AND status=0",
                Long.class,
                postId
        );
        String adminToken = loginAdmin();

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"内容真实，可公开\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bizType").value(4));

        mockMvc.perform(get("/api/c/v1/posts/{postId}", postId)
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(postId))
                .andExpect(jsonPath("$.data.title").value("伦敦周末早午餐避坑指南"));

        mockMvc.perform(get("/api/c/v1/posts").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(postId));
    }

    @Test
    void shouldExposeRejectReasonThenResubmitAndDeleteOwnedPost() throws Exception {
        String userToken = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("巴黎租房避坑", "签约前一定核对押金、能源等级和退租条款。")))
                .andExpect(status().isOk())
                .andReturn();
        long postId = readLong(created, "/data/id");
        long firstTaskId = pendingTaskId(postId);
        String adminToken = loginAdmin();

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/reject", firstTaskId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"缺少可验证的具体信息\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/user/posts/{postId}", postId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(2))
                .andExpect(jsonPath("$.data.auditRemark").value("缺少可验证的具体信息"));

        mockMvc.perform(put("/api/c/v1/posts/{postId}", postId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("巴黎租房避坑清单", "补充：签约前核对押金账户、DPE 能源等级、退租通知期和房屋清单。")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(0))
                .andExpect(jsonPath("$.data.auditRemark").value(""));

        long secondTaskId = pendingTaskId(postId);
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", secondTaskId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/posts/{postId}", postId).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("巴黎租房避坑清单"));

        mockMvc.perform(delete("/api/c/v1/posts/{postId}", postId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/posts/{postId}", postId).header("X-Region", "EU"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/c/v1/user/posts/{postId}", postId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldLikeCommentReportAndFavoriteApprovedPost() throws Exception {
        String authorToken = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("柏林亚洲超市补货观察", "周五下午蔬菜和冷冻食品最齐，周日晚上经常断货。")))
                .andExpect(status().isOk())
                .andReturn();
        long postId = readLong(created, "/data/id");
        String adminToken = loginAdmin();
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(postId))
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        String actorToken = registerUser();
        mockMvc.perform(post("/api/c/v1/posts/{postId}/like", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.liked").value(true))
                .andExpect(jsonPath("$.data.likeCount").value(1));
        mockMvc.perform(post("/api/c/v1/posts/{postId}/like", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.liked").value(false))
                .andExpect(jsonPath("$.data.likeCount").value(0));

        mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"这个补货时间很有用，谢谢。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("这个补货时间很有用，谢谢。"));
        mockMvc.perform(get("/api/c/v1/posts/{postId}/comments", postId).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].content").value("这个补货时间很有用，谢谢。"));

        mockMvc.perform(post("/api/c/v1/posts/{postId}/report", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"部分价格信息可能已经过期\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0));

        mockMvc.perform(post("/api/c/v1/favorites")
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetType\":2,\"targetId\":" + postId + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.target.name").value("柏林亚洲超市补货观察"));
        mockMvc.perform(get("/api/c/v1/favorites")
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU")
                        .param("targetType", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].target.name").value("柏林亚洲超市补货观察"));
    }

    @Test
    void shouldRefreshTopicPostCountsAcrossAuditEditAndDelete() throws Exception {
        String userToken = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title":"话题计数原帖",
                                  "content":"审核通过后才应计入公开话题帖子数。",
                                  "contentType":1,
                                  "images":[],
                                  "topics":["计数旧话题"]
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long postId = readLong(created, "/data/id");
        long oldTopicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topic WHERE region='EU' AND name='计数旧话题'",
                Long.class
        );
        org.assertj.core.api.Assertions.assertThat(topicPostCount(oldTopicId)).isZero();

        String adminToken = loginAdmin();
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(postId))
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());
        org.assertj.core.api.Assertions.assertThat(topicPostCount(oldTopicId)).isEqualTo(1);

        mockMvc.perform(put("/api/c/v1/posts/{postId}", postId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title":"话题计数改帖",
                                  "content":"重新提交后旧话题立即移除，新话题待审核。",
                                  "contentType":1,
                                  "images":[],
                                  "topics":["计数新话题"]
                                }
                                """))
                .andExpect(status().isOk());
        long newTopicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topic WHERE region='EU' AND name='计数新话题'",
                Long.class
        );
        org.assertj.core.api.Assertions.assertThat(topicPostCount(oldTopicId)).isZero();
        org.assertj.core.api.Assertions.assertThat(topicPostCount(newTopicId)).isZero();

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(postId))
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());
        org.assertj.core.api.Assertions.assertThat(topicPostCount(newTopicId)).isEqualTo(1);

        mockMvc.perform(delete("/api/c/v1/posts/{postId}", postId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        org.assertj.core.api.Assertions.assertThat(topicPostCount(newTopicId)).isZero();
    }

    private int topicPostCount(long topicId) {
        return jdbcTemplate.queryForObject(
                "SELECT post_count FROM topic WHERE id=?",
                Integer.class,
                topicId
        );
    }

    private String registerUser() throws Exception {
        String account = "community-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> {
                            request.setRemoteAddr("10.77.11.9");
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "community-test"
                                }
                                """.formatted(account)))
                .andExpect(status().isOk());

        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "社区测试用户",
                                  "preferredRegion": "EU"
                                }
                                """.formatted(account)))
                .andExpect(status().isOk())
                .andReturn();
        return readText(result, "/data/accessToken");
    }

    private String loginAdmin() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "admin",
                                  "password": "admin123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return readText(result, "/data/accessToken");
    }

    private long pendingTaskId(long postId) {
        return jdbcTemplate.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=4 AND biz_id=? AND status=0 ORDER BY id DESC LIMIT 1",
                Long.class,
                postId
        );
    }

    private String postPayload(String title, String content) {
        return """
                {
                  "title": "%s",
                  "content": "%s",
                  "contentType": 1,
                  "images": ["https://files.example/community/guide.jpg"],
                  "topics": ["欧洲生活"]
                }
                """.formatted(title, content);
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
}
