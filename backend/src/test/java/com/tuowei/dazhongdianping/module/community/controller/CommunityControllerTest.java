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
    void shouldShowAuthorCertificationOnApprovedPost() throws Exception {
        RegisteredUser author = registerUser("巴黎生活达人");
        certifyUser(author.userId(), "EU");

        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(author.accessToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("巴黎探店路线图", "左岸喝咖啡、玛黑区吃饭、晚上再去塞纳河边遛弯。")))
                .andExpect(status().isOk())
                .andReturn();
        long postId = readLong(created, "/data/id");

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(postId))
                        .header("Authorization", bearer(loginAdmin()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/posts/{postId}", postId)
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.userName").value("巴黎生活达人"))
                .andExpect(jsonPath("$.data.authorCertification.code").value("local_expert"))
                .andExpect(jsonPath("$.data.authorCertification.label").value("本地达人"));

        mockMvc.perform(get("/api/c/v1/posts")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(postId))
                .andExpect(jsonPath("$.data.list[0].authorCertification.label").value("本地达人"));
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
    void shouldThreadPostCommentsWithinSamePost() throws Exception {
        String authorToken = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("可盖楼帖子", "这条帖子专门给评论盖楼回归用。")))
                .andExpect(status().isOk())
                .andReturn();
        long postId = readLong(created, "/data/id");

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(postId))
                        .header("Authorization", bearer(loginAdmin()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        String parentToken = registerUser();
        MvcResult parentResult = mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", postId)
                        .header("Authorization", bearer(parentToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "顶层先开一楼。"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.parentId").value(0))
                .andReturn();
        long parentCommentId = readLong(parentResult, "/data/id");

        String replyToken = registerUser();
        MvcResult replyResult = mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", postId)
                        .header("Authorization", bearer(replyToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "我跟一层。",
                                  "replyTo": %d
                                }
                                """.formatted(parentCommentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.parentId").value(parentCommentId))
                .andExpect(jsonPath("$.data.replyTo.id").value(parentCommentId))
                .andReturn();
        long replyCommentId = readLong(replyResult, "/data/id");

        mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", postId)
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "我回的是楼中回复。",
                                  "replyTo": %d
                                }
                                """.formatted(replyCommentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.parentId").value(parentCommentId))
                .andExpect(jsonPath("$.data.replyTo.id").value(replyCommentId));

        mockMvc.perform(get("/api/c/v1/posts/{postId}/comments", postId)
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(parentCommentId))
                .andExpect(jsonPath("$.data.list[0].parentId").value(0))
                .andExpect(jsonPath("$.data.list[0].replies.length()").value(2))
                .andExpect(jsonPath("$.data.list[0].replies[0].replyTo.id").value(parentCommentId))
                .andExpect(jsonPath("$.data.list[0].replies[1].replyTo.id").value(replyCommentId));
    }

    @Test
    void shouldRejectReplyingToCommentFromAnotherPost() throws Exception {
        String authorToken = registerUser();
        MvcResult firstPostResult = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("第一条帖子", "先留一个评论目标。")))
                .andExpect(status().isOk())
                .andReturn();
        long firstPostId = readLong(firstPostResult, "/data/id");
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(firstPostId))
                        .header("Authorization", bearer(loginAdmin()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        MvcResult secondPostResult = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("第二条帖子", "这里不能拿第一条的评论串楼。")))
                .andExpect(status().isOk())
                .andReturn();
        long secondPostId = readLong(secondPostResult, "/data/id");
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(secondPostId))
                        .header("Authorization", bearer(loginAdmin()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        MvcResult otherCommentResult = mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", secondPostId)
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "这条评论属于另一条帖子。"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long otherCommentId = readLong(otherCommentResult, "/data/id");

        mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", firstPostId)
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "别跨帖子串楼。",
                                  "replyTo": %d
                                }
                                """.formatted(otherCommentId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void shouldAggregatePostInteractionNotifications() throws Exception {
        String authorToken = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("通知聚合帖子", "连续互动不该把通知列表刷成瀑布。")))
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

        String actorOneToken = registerUser();
        String actorTwoToken = registerUser();

        mockMvc.perform(post("/api/c/v1/posts/{postId}/like", postId)
                        .header("Authorization", bearer(actorOneToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/c/v1/posts/{postId}/like", postId)
                        .header("Authorization", bearer(actorTwoToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", postId)
                        .header("Authorization", bearer(actorOneToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"这条帖子值得补一条评论提醒。\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/notifications/unread-count")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(3));

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].type").value("post.comment"))
                .andExpect(jsonPath("$.data.list[0].aggregateCount").value(1))
                .andExpect(jsonPath("$.data.list[0].linkUrl").value("/community/posts/" + postId))
                .andExpect(jsonPath("$.data.list[1].type").value("post.like"))
                .andExpect(jsonPath("$.data.list[1].aggregateCount").value(2))
                .andExpect(jsonPath("$.data.list[1].linkUrl").value("/community/posts/" + postId));
    }

    @Test
    void shouldNotifyMentionedUsersWhenApprovedPostGoesPublic() throws Exception {
        RegisteredUser author = registerUser("发帖作者");
        RegisteredUser mentioned = registerUser("被艾特用户");

        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(author.accessToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("正文艾特帖子", "审核通过后麻烦 @被艾特用户 来看一下，重复 @被艾特用户 也别刷屏。")))
                .andExpect(status().isOk())
                .andReturn();
        long postId = readLong(created, "/data/id");

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(mentioned.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(postId))
                        .header("Authorization", bearer(loginAdmin()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/notifications/unread-count")
                        .header("Authorization", bearer(mentioned.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(1));

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(mentioned.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].type").value("social.mention"))
                .andExpect(jsonPath("$.data.list[0].actorUserId").value(author.userId()))
                .andExpect(jsonPath("$.data.list[0].actorName").value("发帖作者"))
                .andExpect(jsonPath("$.data.list[0].title").value("有人@了你"))
                .andExpect(jsonPath("$.data.list[0].content").value("发帖作者 在帖子《正文艾特帖子》中提到了你"))
                .andExpect(jsonPath("$.data.list[0].aggregateCount").value(1))
                .andExpect(jsonPath("$.data.list[0].linkUrl").value("/community/posts/" + postId));
    }

    @Test
    void shouldNotifyCommentMentionsAndSkipInvalidTargets() throws Exception {
        RegisteredUser author = registerUser("原帖作者");
        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(author.accessToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("评论艾特帖子", "给评论里的 @提醒 做回归。")))
                .andExpect(status().isOk())
                .andReturn();
        long postId = readLong(created, "/data/id");

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingTaskId(postId))
                        .header("Authorization", bearer(loginAdmin()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        RegisteredUser mentioned = registerUser("楼里被艾特");
        RegisteredUser actor = registerUser("评论人自己");
        RegisteredUser duplicateOne = registerUser("重名用户");
        RegisteredUser duplicateTwo = registerUser("重名用户");

        mockMvc.perform(post("/api/c/v1/posts/{postId}/comments", postId)
                        .header("Authorization", bearer(actor.accessToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "@楼里被艾特 麻烦看下，重复 @楼里被艾特 不要再刷一次，@评论人自己 自己别提醒自己，@重名用户 这种重名别乱发，@不存在用户 也别硬凑。"
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/notifications/unread-count")
                        .header("Authorization", bearer(mentioned.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(1));

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(mentioned.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].type").value("social.mention"))
                .andExpect(jsonPath("$.data.list[0].actorUserId").value(actor.userId()))
                .andExpect(jsonPath("$.data.list[0].actorName").value("评论人自己"))
                .andExpect(jsonPath("$.data.list[0].title").value("有人@了你"))
                .andExpect(jsonPath("$.data.list[0].content").value("评论人自己 在帖子《评论艾特帖子》的评论中提到了你"))
                .andExpect(jsonPath("$.data.list[0].aggregateCount").value(1))
                .andExpect(jsonPath("$.data.list[0].linkUrl").value("/community/posts/" + postId));

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(duplicateOne.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(duplicateTwo.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
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

    @Test
    void shouldRepostApprovedPostIdempotentlyAndHonorRegionAndVisibility() throws Exception {
        String authorToken = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(authorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("可转发的社区帖子", "只有公开审核通过的内容才能被转发。")))
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
        mockMvc.perform(post("/api/c/v1/posts/{postId}/repost", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.postId").value(postId))
                .andExpect(jsonPath("$.data.reposted").value(true))
                .andExpect(jsonPath("$.data.repostCount").value(1));

        mockMvc.perform(post("/api/c/v1/posts/{postId}/repost", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reposted").value(true))
                .andExpect(jsonPath("$.data.repostCount").value(1));

        mockMvc.perform(get("/api/c/v1/posts/{postId}", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.repostCount").value(1))
                .andExpect(jsonPath("$.data.repostedByCurrentUser").value(true));

        mockMvc.perform(post("/api/c/v1/posts/{postId}/repost", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound());

        MvcResult pendingCreated = mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(postPayload("待审核不可转发", "审核前不应产生转发关系。")))
                .andExpect(status().isOk())
                .andReturn();
        long pendingPostId = readLong(pendingCreated, "/data/id");
        mockMvc.perform(post("/api/c/v1/posts/{postId}/repost", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/c/v1/posts/{postId}/repost", pendingPostId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());

        mockMvc.perform(delete("/api/c/v1/posts/{postId}/repost", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reposted").value(false))
                .andExpect(jsonPath("$.data.repostCount").value(0));

        mockMvc.perform(delete("/api/c/v1/posts/{postId}/repost", postId)
                        .header("Authorization", bearer(actorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.reposted").value(false))
                .andExpect(jsonPath("$.data.repostCount").value(0));

        org.assertj.core.api.Assertions.assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM post_repost WHERE post_id=? AND user_id=(SELECT id FROM app_user WHERE email LIKE 'community-%' ORDER BY id DESC LIMIT 1)",
                Integer.class,
                postId)).isZero();
        org.assertj.core.api.Assertions.assertThat(jdbcTemplate.queryForObject(
                "SELECT repost_count FROM post WHERE id=?", Integer.class, postId)).isZero();
    }

    private int topicPostCount(long topicId) {
        return jdbcTemplate.queryForObject(
                "SELECT post_count FROM topic WHERE id=?",
                Integer.class,
                topicId
        );
    }

    private String registerUser() throws Exception {
        return registerUser("社区测试用户").accessToken();
    }

    private RegisteredUser registerUser(String nickname) throws Exception {
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
                                  "nickname": "%s",
                                  "preferredRegion": "EU"
                                }
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andReturn();
        return new RegisteredUser(readLong(result, "/data/user/id"), readText(result, "/data/accessToken"), nickname);
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

    private void certifyUser(long userId, String region) {
        jdbcTemplate.update("""
                        INSERT INTO user_expert_certification(
                            user_id,
                            region,
                            reason,
                            status,
                            reject_reason,
                            audit_by,
                            submitted_at,
                            audited_at,
                            effective_start_at,
                            effective_end_at
                        )
                        VALUES (?, ?, ?, 2, '', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL)
                        """,
                userId,
                region,
                "社区公开内容稳定，补一枚达人认证给展示层用。");
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

    private record RegisteredUser(long userId, String accessToken, String nickname) {}
}
