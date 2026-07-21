package com.tuowei.dazhongdianping.module.review.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
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
class ReviewControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRequireLoginWhenCreatingReview() throws Exception {
        mockMvc.perform(post("/api/c/v1/reviews")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001L, "游客乱冲点评", 5, 5, 4, 5, 120.00)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldReuseFirstResponseForSameIdempotencyKeyAndRejectBodyMismatch() throws Exception {
        String userToken = registerUser("review-idempotent@example.com", "幂等用户");
        String idempotencyKey = "review-create-key-0001";
        String firstPayload = reviewPayload(10001L, "同一个幂等键重复提交，只能落一条点评。", 5, 5, 4, 5, 128.00);

        MvcResult firstResult = mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .header("Idempotency-Key", idempotencyKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(firstPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();
        long firstReviewId = readLong(firstResult, "/data/id");

        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .header("Idempotency-Key", idempotencyKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(firstPayload))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(firstReviewId));

        mockMvc.perform(get("/api/c/v1/user/reviews")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(firstReviewId));

        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .header("Idempotency-Key", idempotencyKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001L, "同一个幂等键换请求体，必须拦住。", 5, 5, 4, 5, 128.00)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value(409))
                .andExpect(jsonPath("$.messageKey").value("common.idempotency_conflict"));
    }

    @Test
    void shouldCreateReviewAuditAndPublishAfterPass() throws Exception {
        String userToken = registerUser("review-pass@example.com", "点评人甲");

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001L, "锅底很稳，肉片也新鲜，值回票价。", 5, 5, 4, 5, 156.00)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.auditStatus").value(0))
                .andExpect(jsonPath("$.data.images.length()").value(2))
                .andReturn();

        long reviewId = readLong(createResult, "/data/id");

        mockMvc.perform(get("/api/c/v1/user/reviews")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(reviewId))
                .andExpect(jsonPath("$.data.list[0].auditStatus").value(0));

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1));

        String adminToken = loginAdmin();
        long taskId = pendingAuditTaskId(reviewId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "remark": "内容正常，允许展示"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.bizId").value(reviewId));

        mockMvc.perform(get("/api/c/v1/reviews/{reviewId}", reviewId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(reviewId))
                .andExpect(jsonPath("$.data.images.length()").value(2))
                .andExpect(jsonPath("$.data.auditStatus").value(1));

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].id").value(reviewId));

        mockMvc.perform(get("/api/c/v1/shops/10001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.score").value(4.9));
    }

    @Test
    void shouldShowAuthorCertificationOnPublicReviewDetailAndPreview() throws Exception {
        String account = "review-expert@example.com";
        String userToken = registerUser(account, "认证点评人");
        certifyUser(account, "CN");

        long reviewId = createReview(userToken, 10001L, "这条点评拿来验证达人标识展示。", 5, 5, 4, 5, 108.00);
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingAuditTaskId(reviewId))
                        .header("Authorization", bearer(loginAdmin()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/reviews/{reviewId}", reviewId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.userName").value("认证点评人"))
                .andExpect(jsonPath("$.data.authorCertification.code").value("local_expert"))
                .andExpect(jsonPath("$.data.authorCertification.label").value("本地达人"));

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(reviewId))
                .andExpect(jsonPath("$.data.list[0].authorCertification.label").value("本地达人"));
    }

    @Test
    void shouldGrantGrowthAndPointsWhenCreatingReview() throws Exception {
        jdbcTemplate.update("UPDATE growth_rule SET enabled = FALSE WHERE action = 'review_image'");
        String account = "review-growth@example.com";
        String userToken = registerUser(account, "成长用户");

        long firstReviewId = createReview(userToken, 10001L, "第一条点评先把成长值顶上去。", 5, 5, 4, 5, 88.00);
        long secondReviewId = createReview(userToken, 10002L, "第二条点评继续补积分和等级。", 4, 4, 4, 4, 66.00);

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.growthValue").value(20))
                .andExpect(jsonPath("$.data.points").value(10))
                .andExpect(jsonPath("$.data.level").value(2));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM growth_points_log WHERE user_id = (SELECT id FROM app_user WHERE email = ?)",
                Long.class,
                account
        )).isEqualTo(4L);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM growth_points_log WHERE action = 'review_create' AND biz_id = ?",
                Long.class,
                firstReviewId
        )).isEqualTo(2L);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM growth_points_log WHERE action = 'review_create' AND biz_id = ?",
                Long.class,
                secondReviewId
        )).isEqualTo(2L);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT MAX(balance_after) FROM growth_points_log WHERE user_id = (SELECT id FROM app_user WHERE email = ?) AND type = 1",
                Integer.class,
                account
        )).isEqualTo(20);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT MAX(balance_after) FROM growth_points_log WHERE user_id = (SELECT id FROM app_user WHERE email = ?) AND type = 2",
                Integer.class,
                account
        )).isEqualTo(10);
    }

    @Test
    void shouldGrantGrowthForReviewImagesOncePerReview() throws Exception {
        jdbcTemplate.update("UPDATE growth_rule SET growth_value = 4, points = 2, daily_limit = 10, enabled = TRUE WHERE action = 'review_image'");
        String account = "review-image-growth@example.com";
        String userToken = registerUser(account, "带图成长用户");

        long reviewId = createReview(userToken, 10001L, "两张图也只按这条点评奖励一次带图成长。", 5, 5, 4, 5, 88.00);

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.growthValue").value(14))
                .andExpect(jsonPath("$.data.points").value(7))
                .andExpect(jsonPath("$.data.level").value(1));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM growth_points_log WHERE user_id = (SELECT id FROM app_user WHERE email = ?) AND action = 'review_image' AND biz_id = ?",
                Long.class,
                account,
                reviewId
        )).isEqualTo(2L);
    }

    @Test
    void shouldGrantGrowthToReviewAuthorWhenAnotherUserLikesPublicReviewOnlyOnce() throws Exception {
        jdbcTemplate.update("UPDATE growth_rule SET enabled = FALSE WHERE action IN ('review_create', 'review_image')");
        jdbcTemplate.update("UPDATE growth_rule SET growth_value = 7, points = 3, daily_limit = 20, enabled = TRUE WHERE action = 'review_liked'");
        String authorAccount = "review-liked-author@example.com";
        String authorToken = registerUser(authorAccount, "被赞作者");
        long reviewId = createReview(authorToken, 10001L, "这条公开点评用来验证获赞奖励。", 5, 5, 5, 5, 108.00);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingAuditTaskId(reviewId))
                        .header("Authorization", bearer(loginAdmin()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/c/v1/reviews/{reviewId}/like", reviewId)
                        .header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.liked").value(true));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM growth_points_log WHERE user_id = (SELECT id FROM app_user WHERE email = ?) AND action = 'review_liked' AND biz_id = ?",
                Long.class,
                authorAccount,
                reviewId
        )).isZero();

        String likerToken = registerUser("review-liked-fan@example.com", "点赞用户");
        mockMvc.perform(post("/api/c/v1/reviews/{reviewId}/like", reviewId)
                        .header("Authorization", bearer(likerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.liked").value(true));

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.growthValue").value(7))
                .andExpect(jsonPath("$.data.points").value(3));

        mockMvc.perform(post("/api/c/v1/reviews/{reviewId}/like", reviewId)
                        .header("Authorization", bearer(likerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.liked").value(false));
        mockMvc.perform(post("/api/c/v1/reviews/{reviewId}/like", reviewId)
                        .header("Authorization", bearer(likerToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.liked").value(true));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM growth_points_log WHERE user_id = (SELECT id FROM app_user WHERE email = ?) AND action = 'review_liked' AND biz_id = ?",
                Long.class,
                authorAccount,
                reviewId
        )).isEqualTo(2L);
    }

    @Test
    void shouldRejectEditResubmitAndDeleteOwnReview() throws Exception {
        String userToken = registerUser("review-reject@example.com", "点评人乙");
        long reviewId = createReview(userToken, 10002L, "第一版内容太水了。", 3, 3, 3, 3, 68.00);

        String adminToken = loginAdmin();
        long taskId = pendingAuditTaskId(reviewId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/reject", taskId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "内容太敷衍，请补充真实体验"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.status").value(2));

        mockMvc.perform(get("/api/c/v1/user/reviews")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(reviewId))
                .andExpect(jsonPath("$.data.list[0].auditStatus").value(2))
                .andExpect(jsonPath("$.data.list[0].auditRemark").value("内容太敷衍，请补充真实体验"));

        mockMvc.perform(get("/api/c/v1/user/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").value(reviewId))
                .andExpect(jsonPath("$.data.auditStatus").value(2))
                .andExpect(jsonPath("$.data.images.length()").value(2));

        mockMvc.perform(get("/api/c/v1/reviews/{reviewId}", reviewId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(put("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10002L, "第二版补全了环境、咖啡和服务体验，重新提审。", 4, 4, 5, 4, 78.00)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.auditStatus").value(0))
                .andExpect(jsonPath("$.data.auditRemark").value(""));

        long resubmittedTaskId = pendingAuditTaskId(reviewId);
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", resubmittedTaskId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "remark": "修改后可展示"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        mockMvc.perform(delete("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        mockMvc.perform(get("/api/c/v1/reviews/{reviewId}", reviewId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(get("/api/c/v1/user/reviews")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
    }

    @Test
    void shouldToggleLikeCreateCommentAndReportPublicReview() throws Exception {
        String userToken = registerUser("review-interact@example.com", "互动用户");

        mockMvc.perform(post("/api/c/v1/reviews/1/like")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.reviewId").value(1))
                .andExpect(jsonPath("$.data.liked").value(true))
                .andExpect(jsonPath("$.data.likeCount").value(3));

        mockMvc.perform(get("/api/c/v1/reviews/1")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.likeCount").value(3))
                .andExpect(jsonPath("$.data.likedByCurrentUser").value(true));

        mockMvc.perform(post("/api/c/v1/reviews/1/like")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.liked").value(false))
                .andExpect(jsonPath("$.data.likeCount").value(2));

        mockMvc.perform(post("/api/c/v1/reviews/1/comments")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "这条点评不空不水，看得出是真吃过。"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.reviewId").value(1))
                .andExpect(jsonPath("$.data.content").value("这条点评不空不水，看得出是真吃过。"))
                .andExpect(jsonPath("$.data.mine").value(true));

        mockMvc.perform(get("/api/c/v1/reviews/1/comments")
                        .header("Authorization", bearer(userToken))
                        .param("page", "1")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.total").value(3))
                .andExpect(jsonPath("$.data.list[0].content").value("这条点评不空不水，看得出是真吃过。"))
                .andExpect(jsonPath("$.data.list[0].mine").value(true));

        mockMvc.perform(get("/api/c/v1/reviews/1")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.commentCount").value(3))
                .andExpect(jsonPath("$.data.likedByCurrentUser").value(false));

        String adminToken = loginAdmin();
        long pendingBefore = pendingAuditTaskTotal(adminToken);

        mockMvc.perform(post("/api/c/v1/reviews/1/report")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "疑似存在夸大宣传，想让后台复核一下。"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.reviewId").value(1))
                .andExpect(jsonPath("$.data.status").value(0));

        mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(adminToken))
                        .param("bizType", "3")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(pendingBefore + 1));

        mockMvc.perform(post("/api/c/v1/reviews/1/report")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "同一个人别反复刷举报。"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void shouldThreadReviewCommentsWithinSameReview() throws Exception {
        String parentToken = registerUser("review-thread-parent@example.com", "点评楼主");
        MvcResult parentResult = mockMvc.perform(post("/api/c/v1/reviews/1/comments")
                        .header("Authorization", bearer(parentToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "这条点评下面先起一层楼。"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.parentId").value(0))
                .andReturn();
        long parentCommentId = readLong(parentResult, "/data/id");

        String replyToken = registerUser("review-thread-reply@example.com", "跟楼用户");
        MvcResult replyResult = mockMvc.perform(post("/api/c/v1/reviews/1/comments")
                        .header("Authorization", bearer(replyToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "我来跟一层。",
                                  "replyTo": %d
                                }
                                """.formatted(parentCommentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.parentId").value(parentCommentId))
                .andExpect(jsonPath("$.data.replyTo.id").value(parentCommentId))
                .andExpect(jsonPath("$.data.replyTo.userName").value("点评楼主"))
                .andReturn();
        long replyCommentId = readLong(replyResult, "/data/id");

        String nestedReplyToken = registerUser("review-thread-nested@example.com", "楼中回复用户");
        mockMvc.perform(post("/api/c/v1/reviews/1/comments")
                        .header("Authorization", bearer(nestedReplyToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "我回的是楼中回复，但不能再无限套娃。",
                                  "replyTo": %d
                                }
                                """.formatted(replyCommentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.parentId").value(parentCommentId))
                .andExpect(jsonPath("$.data.replyTo.id").value(replyCommentId))
                .andExpect(jsonPath("$.data.replyTo.userName").value("跟楼用户"));

        mockMvc.perform(get("/api/c/v1/reviews/1/comments")
                        .header("Authorization", bearer(nestedReplyToken))
                        .param("page", "1")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(3))
                .andExpect(jsonPath("$.data.list[0].id").value(parentCommentId))
                .andExpect(jsonPath("$.data.list[0].parentId").value(0))
                .andExpect(jsonPath("$.data.list[0].replies.length()").value(2))
                .andExpect(jsonPath("$.data.list[0].replies[0].replyTo.id").value(parentCommentId))
                .andExpect(jsonPath("$.data.list[0].replies[1].replyTo.id").value(replyCommentId))
                .andExpect(jsonPath("$.data.list[0].replies[1].mine").value(true));
    }

    @Test
    void shouldRejectReplyingToCommentFromAnotherReview() throws Exception {
        String userToken = registerUser("review-cross-reply@example.com", "串楼用户");
        MvcResult otherReviewComment = mockMvc.perform(post("/api/c/v1/reviews/2/comments")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "这条评论属于另一条点评。"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long otherCommentId = readLong(otherReviewComment, "/data/id");

        mockMvc.perform(post("/api/c/v1/reviews/1/comments")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "别想跨点评串楼。",
                                  "replyTo": %d
                                }
                                """.formatted(otherCommentId)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void shouldAggregateReviewInteractionNotifications() throws Exception {
        String authorToken = registerUser("review-notification-author@example.com", "点评通知作者");
        long reviewId = createReview(authorToken, 10001L, "这条点评专门用来验通知聚合。", 5, 5, 5, 5, 128.00);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingAuditTaskId(reviewId))
                        .header("Authorization", bearer(loginAdmin()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        String likerToken = registerUser("review-notification-like@example.com", "点赞提醒用户");
        String commenterToken = registerUser("review-notification-comment@example.com", "评论提醒用户");

        mockMvc.perform(post("/api/c/v1/reviews/{reviewId}/like", reviewId)
                        .header("Authorization", bearer(likerToken)))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/c/v1/reviews/{reviewId}/like", reviewId)
                        .header("Authorization", bearer(commenterToken)))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/c/v1/reviews/{reviewId}/comments", reviewId)
                        .header("Authorization", bearer(commenterToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "我再补一条评论，把聚合通知打实。"
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/notifications/unread-count")
                        .header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(3));

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(authorToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].type").value("review.comment"))
                .andExpect(jsonPath("$.data.list[0].aggregateCount").value(1))
                .andExpect(jsonPath("$.data.list[0].linkUrl").value("/reviews/" + reviewId))
                .andExpect(jsonPath("$.data.list[1].type").value("review.like"))
                .andExpect(jsonPath("$.data.list[1].aggregateCount").value(2))
                .andExpect(jsonPath("$.data.list[1].linkUrl").value("/reviews/" + reviewId));
    }

    @Test
    void shouldRejectCrossRegionReviewAccessAndInteractions() throws Exception {
        String userToken = registerUser("review-region@example.com", "区域用户");

        mockMvc.perform(get("/api/c/v1/reviews/3")
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(get("/api/c/v1/reviews/3/comments")
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(post("/api/c/v1/reviews/3/like")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(post("/api/c/v1/reviews/3/comments")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "content": "跨区评论必须被拦住。"
                                }
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(post("/api/c/v1/reviews/3/report")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "跨区举报必须被拦住。"
                                }
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(get("/api/c/v1/reviews/3")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.region").doesNotExist())
                .andExpect(jsonPath("$.data.id").value(3));
    }

    @Test
    void shouldRestrictOwnedReviewsToCurrentRequestRegion() throws Exception {
        String userToken = registerUser("review-owned-region@example.com", "跨区点评用户");
        MvcResult createResult = mockMvc.perform(post("/api/c/v1/reviews")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(20001L, "这条点评只属于欧洲区。", 5, 5, 4, 5, 36.00)
                                .replace("\"currency\": \"CNY\"", "\"currency\": \"EUR\"")))
                .andExpect(status().isOk())
                .andReturn();
        long reviewId = readLong(createResult, "/data/id");

        mockMvc.perform(get("/api/c/v1/user/reviews")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));

        mockMvc.perform(get("/api/c/v1/user/reviews/{reviewId}", reviewId)
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isNotFound());

        mockMvc.perform(put("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(20001L, "不能从中国区修改欧洲区点评。", 4, 4, 4, 4, 30.00)))
                .andExpect(status().isNotFound());

        mockMvc.perform(delete("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/c/v1/user/reviews")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(reviewId));
    }

    @Test
    void shouldRejectCrossRegionAdminAuditDecision() throws Exception {
        String userToken = registerUser("review-admin-region@example.com", "审核区域用户");
        MvcResult createResult = mockMvc.perform(post("/api/c/v1/reviews")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(20001L, "这条欧洲区点评只能由欧洲区请求审核。", 5, 5, 4, 5, 42.00)
                                .replace("\"currency\": \"CNY\"", "\"currency\": \"EUR\"")))
                .andExpect(status().isOk())
                .andReturn();
        long reviewId = readLong(createResult, "/data/id");
        long taskId = pendingAuditTaskId(reviewId);
        String adminToken = loginAdmin();

        mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(adminToken))
                        .param("region", "EU")
                        .param("bizType", "3")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));
    }

    @Test
    void shouldInvalidateOldPendingTaskBeforeEditingReview() throws Exception {
        String userToken = registerUser("review-edit-task@example.com", "编辑任务用户");
        long reviewId = createReview(userToken, 10001L, "旧正文等待审核。", 4, 4, 4, 4, 88.00);
        long oldTaskId = pendingAuditTaskId(reviewId);

        mockMvc.perform(put("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001L, "这是编辑后的最新正文，只能由新任务审核。", 5, 5, 5, 5, 98.00)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(0));

        assertThat(auditTaskStatus(oldTaskId)).isEqualTo(2);
        assertThat(auditTaskRemark(oldTaskId)).startsWith("任务失效：点评已编辑");
        assertThat(pendingAuditTaskCount(reviewId)).isEqualTo(1);

        String adminToken = loginAdmin();
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", oldTaskId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "remark": "旧任务不得放行新正文"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));

        mockMvc.perform(get("/api/c/v1/user/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("这是编辑后的最新正文，只能由新任务审核。"))
                .andExpect(jsonPath("$.data.auditStatus").value(0));
    }

    @Test
    void shouldInvalidatePendingTaskWhenDeletingReview() throws Exception {
        String userToken = registerUser("review-delete-task@example.com", "删除任务用户");
        long reviewId = createReview(userToken, 10002L, "删除前仍在等待审核。", 4, 4, 4, 4, 66.00);
        long oldTaskId = pendingAuditTaskId(reviewId);

        mockMvc.perform(delete("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk());

        assertThat(auditTaskStatus(oldTaskId)).isEqualTo(2);
        assertThat(auditTaskRemark(oldTaskId)).startsWith("任务失效：点评已删除");
        assertThat(pendingAuditTaskCount(reviewId)).isZero();

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", oldTaskId)
                        .header("Authorization", bearer(loginAdmin()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void shouldAllowOnlyOneDecisionForRepeatedAuditRequest() throws Exception {
        String userToken = registerUser("review-repeat-audit@example.com", "重复审核用户");
        long reviewId = createReview(userToken, 10001L, "同一个任务只能审核一次。", 5, 5, 5, 5, 108.00);
        long taskId = pendingAuditTaskId(reviewId);
        String adminToken = loginAdmin();

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/reject", taskId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "重复请求不应覆盖第一次结果"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT audit_status FROM review WHERE id = ?",
                Integer.class,
                reviewId
        )).isEqualTo(1);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE target = ?",
                Long.class,
                "review:" + reviewId
        )).isEqualTo(1L);
    }

    @Test
    void shouldHideReportedPublicReviewRecalculateShopAndResolveReportsAfterReject() throws Exception {
        String reporterToken = registerUser("review-report-reject@example.com", "举报驳回用户");
        String reason = "复核后若驳回，门店聚合和举报状态都要立即更新。";

        mockMvc.perform(post("/api/c/v1/reviews/1/report")
                        .header("Authorization", bearer(reporterToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "%s"
                                }
                                """.formatted(reason)))
                .andExpect(status().isOk());

        long taskId = pendingAuditTaskId(1L);
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/reject", taskId)
                        .header("Authorization", bearer(loginAdmin()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "举报成立，隐藏点评"
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/reviews/1"))
                .andExpect(status().isNotFound());
        assertThat(jdbcTemplate.queryForObject(
                "SELECT review_count FROM shop WHERE id = 10001",
                Integer.class
        )).isZero();
        assertThat(jdbcTemplate.queryForObject(
                "SELECT score FROM shop WHERE id = 10001",
                BigDecimal.class
        )).isEqualByComparingTo("0.0");
        assertThat(jdbcTemplate.queryForObject(
                "SELECT status FROM review_report WHERE review_id = 1 AND reason = ?",
                Integer.class,
                reason
        )).isEqualTo(1);
    }

    @Test
    void shouldResolveRelatedReportsAfterPass() throws Exception {
        String reporterToken = registerUser("review-report-pass@example.com", "举报通过用户");
        String reason = "复核通过后也不能让举报一直挂在待处理。";

        mockMvc.perform(post("/api/c/v1/reviews/2/report")
                        .header("Authorization", bearer(reporterToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "%s"
                                }
                                """.formatted(reason)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", pendingAuditTaskId(2L))
                        .header("Authorization", bearer(loginAdmin()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isOk());

        assertThat(jdbcTemplate.queryForObject(
                "SELECT status FROM review_report WHERE review_id = 2 AND reason = ?",
                Integer.class,
                reason
        )).isEqualTo(1);
    }

    private long createReview(String accessToken,
                              long shopId,
                              String content,
                              int scoreOverall,
                              int scoreTaste,
                              int scoreEnv,
                              int scoreService,
                              double cost) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(shopId, content, scoreOverall, scoreTaste, scoreEnv, scoreService, cost)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();
        return readLong(result, "/data/id");
    }

    private String registerUser(String account, String nickname) throws Exception {
        String deviceId = "web-review-" + account.replaceAll("[^a-zA-Z0-9]", "-");
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> {
                            request.setRemoteAddr(testIpFor(account));
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "%s"
                                }
                                """.formatted(account, deviceId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "%s",
                                  "preferredRegion": "CN"
                                }
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();
        return readText(registerResult, "/data/accessToken");
    }

    private String testIpFor(String account) {
        int hash = account.hashCode();
        return "10.%d.%d.%d".formatted(
                Math.floorMod(hash, 223) + 1,
                Math.floorMod(hash / 223, 223) + 1,
                Math.floorMod(hash / (223 * 223), 223) + 1
        );
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
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();
        return readText(result, "/data/accessToken");
    }

    private void certifyUser(String account, String region) {
        Long userId = jdbcTemplate.queryForObject(
                "SELECT id FROM app_user WHERE email = ?",
                Long.class,
                account
        );
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
                "公开点评持续稳定输出，可展示达人标识。");
    }

    private long pendingAuditTaskId(Long reviewId) {
        return jdbcTemplate.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type = 3 AND biz_id = ? AND status = 0 ORDER BY id DESC LIMIT 1",
                Long.class,
                reviewId
        );
    }

    private int pendingAuditTaskCount(Long reviewId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type = 3 AND biz_id = ? AND status = 0",
                Integer.class,
                reviewId
        );
    }

    private int auditTaskStatus(Long taskId) {
        return jdbcTemplate.queryForObject(
                "SELECT status FROM audit_task WHERE id = ?",
                Integer.class,
                taskId
        );
    }

    private String auditTaskRemark(Long taskId) {
        return jdbcTemplate.queryForObject(
                "SELECT remark FROM audit_task WHERE id = ?",
                String.class,
                taskId
        );
    }

    private long pendingAuditTaskTotal(String adminToken) throws Exception {
        MvcResult result = mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(adminToken))
                        .param("bizType", "3")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();
        return readLong(result, "/data/total");
    }

    private String reviewPayload(long shopId,
                                 String content,
                                 int scoreOverall,
                                 int scoreTaste,
                                 int scoreEnv,
                                 int scoreService,
                                 double cost) {
        return """
                {
                  "shopId": %d,
                  "content": "%s",
                  "scoreOverall": %d,
                  "scoreTaste": %d,
                  "scoreEnv": %d,
                  "scoreService": %d,
                  "cost": %.2f,
                  "currency": "CNY",
                  "tags": ["出锅稳", "适合聚餐"],
                  "images": [
                    "https://placehold.co/800x520/f97316/ffffff?text=Review+1",
                    "https://placehold.co/800x520/ea580c/ffffff?text=Review+2"
                  ]
                }
                """.formatted(shopId, content, scoreOverall, scoreTaste, scoreEnv, scoreService, cost);
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
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
