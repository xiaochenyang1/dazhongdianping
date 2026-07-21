package com.tuowei.dazhongdianping.module.auth.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.auth.service.SendCodeRateLimitService;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import org.junit.jupiter.api.BeforeEach;
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
class UserPrivacyControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private SendCodeRateLimitService sendCodeRateLimitService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void resetState() {
        sendCodeRateLimitService.clearAll();
    }

    @Test
    void shouldCreateExportTaskExposeOverviewAndDownloadZip() throws Exception {
        SessionFixture session = registerUser("privacy-export@example.com", "PrivacyPass1!");
        createReview(session.accessToken(), 10001L, "隐私导出测试点评，别整空文件糊弄人。");

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-export-task-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "modules": ["account", "reviews"],
                                  "format": "zip"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.statusText").value("可下载"))
                .andExpect(jsonPath("$.data.modules[0]").value("account"))
                .andExpect(jsonPath("$.data.modules[1]").value("reviews"))
                .andExpect(jsonPath("$.data.downloadUrl").value(
                        org.hamcrest.Matchers.startsWith("/api/c/v1/privacy/export-tasks/")
                ))
                .andReturn();

        String taskId = readText(createResult, "/data/id");

        mockMvc.perform(get("/api/c/v1/privacy/overview")
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.exportRule.defaultFormat").value("zip"))
                .andExpect(jsonPath("$.data.latestExportTask.id").value(Long.parseLong(taskId)))
                .andExpect(jsonPath("$.data.latestExportTask.statusText").value("可下载"));

        mockMvc.perform(get("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .param("page", "1")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(Long.parseLong(taskId)))
                .andExpect(jsonPath("$.data.list[0].statusText").value("可下载"));

        MvcResult downloadResult = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download", taskId)
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk())
                .andReturn();

        String zipContent = unzipSingleEntry(downloadResult.getResponse().getContentAsByteArray());
        JsonNode exportRoot = objectMapper.readTree(zipContent);
        assertJsonText(exportRoot, "/modules/account/email", "privacy-export@example.com");
        assertJsonText(exportRoot, "/modules/reviews/0/content", "隐私导出测试点评，别整空文件糊弄人。");
        assertJsonText(exportRoot, "/meta/userId", session.userId());
    }

    @Test
    void shouldExportOwnedPostsWithoutPretendingMessagesExist() throws Exception {
        SessionFixture session = registerUser("privacy-posts@example.com", "PostsPass1!");
        mockMvc.perform(post("/api/c/v1/posts")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "隐私导出里的社区帖子",
                                  "content": "这条帖子必须真实进入导出结果。",
                                  "contentType": 1,
                                  "images": ["https://files.example/privacy-post.jpg"],
                                  "topics": ["隐私测试"]
                                }
                                """))
                .andExpect(status().isOk());

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-post-export-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"modules\":[\"posts\"],\"format\":\"zip\"}"))
                .andExpect(status().isOk())
                .andReturn();

        String taskId = readText(createResult, "/data/id");
        MvcResult download = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download", taskId)
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode root = objectMapper.readTree(unzipSingleEntry(download.getResponse().getContentAsByteArray()));

        assertJsonText(root, "/modules/posts/0/title", "隐私导出里的社区帖子");
        assertJsonText(root, "/modules/posts/0/content", "这条帖子必须真实进入导出结果。");
        if (!root.at("/modules/messages").isMissingNode()) {
            throw new AssertionError("私信尚未实现，不能导出空 messages 模块冒充完成");
        }
    }

    @Test
    void shouldExportRepostRelationshipsWithPostData() throws Exception {
        SessionFixture session = registerUser("privacy-reposts@example.com", "RepostsPass1!");
        jdbcTemplate.update("""
                INSERT INTO post(user_id,region,user_name,title,content,content_type,like_count,comment_count,
                                 audit_status,audit_remark,status,is_deleted)
                VALUES(91001,'EU','原帖作者','隐私导出的被转发帖子','公开帖子内容',1,0,0,1,'',1,FALSE)
                """);
        Long postId = jdbcTemplate.queryForObject(
                "SELECT id FROM post WHERE title='隐私导出的被转发帖子'", Long.class);

        mockMvc.perform(post("/api/c/v1/posts/{postId}/repost", postId)
                        .header("Authorization", bearer(session.accessToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.repostCount").value(1));

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-repost-export-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"modules\":[\"posts\"],\"format\":\"zip\"}"))
                .andExpect(status().isOk())
                .andReturn();
        MvcResult download = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download",
                        readText(createResult, "/data/id"))
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode root = objectMapper.readTree(unzipSingleEntry(download.getResponse().getContentAsByteArray()));

        assertJsonText(root, "/modules/posts/0/recordType", "repost");
        assertJsonText(root, "/modules/posts/0/postId", postId);
        assertJsonText(root, "/modules/posts/0/title", "隐私导出的被转发帖子");
        assertJsonText(root, "/modules/posts/0/region", "EU");
    }

    @Test
    void shouldExportRealFollowingAndFollowerRelationships() throws Exception {
        SessionFixture session = registerUser("privacy-follows@example.com", "FollowsPass1!");
        jdbcTemplate.update("INSERT INTO app_user(nickname,email,preferred_region,status,is_deleted) VALUES(?,?,?,?,FALSE)",
                "隐私关系用户", "privacy-related@example.com", "EU", 1);
        Long relatedUserId = jdbcTemplate.queryForObject("SELECT id FROM app_user WHERE email=?", Long.class, "privacy-related@example.com");
        jdbcTemplate.update("INSERT INTO user_follow(follower_user_id,followed_user_id) VALUES(?,?)", session.userId(), relatedUserId);
        jdbcTemplate.update("INSERT INTO user_follow(follower_user_id,followed_user_id) VALUES(?,?)", relatedUserId, session.userId());

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-follows-export-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"modules\":[\"follows\"],\"format\":\"zip\"}"))
                .andExpect(status().isOk())
                .andReturn();
        String taskId = readText(createResult, "/data/id");
        MvcResult download = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download", taskId)
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk()).andReturn();
        JsonNode root = objectMapper.readTree(unzipSingleEntry(download.getResponse().getContentAsByteArray()));
        assertJsonText(root, "/modules/follows/following/0/nickname", "隐私关系用户");
        assertJsonText(root, "/modules/follows/followers/0/nickname", "隐私关系用户");
    }

    @Test
    void shouldExportMessagesAndGovernThemWhenAccountIsDeleted() throws Exception {
        SessionFixture session = registerUser("privacy-messages@example.com", "MessagesPass1!");
        jdbcTemplate.update("INSERT INTO app_user(nickname,email,preferred_region,status,is_deleted) VALUES('私信对端','privacy-peer@example.com','CN',1,FALSE)");
        Long peerId = jdbcTemplate.queryForObject("SELECT id FROM app_user WHERE email='privacy-peer@example.com'", Long.class);
        jdbcTemplate.update("INSERT INTO conversation(user_a,user_b,last_message_preview,last_message_at) VALUES(?,?,?,CURRENT_TIMESTAMP)",
                Math.min(session.userId(), peerId), Math.max(session.userId(), peerId), "导出私信内容");
        Long conversationId = jdbcTemplate.queryForObject("SELECT id FROM conversation WHERE user_a=? AND user_b=?", Long.class,
                Math.min(session.userId(), peerId), Math.max(session.userId(), peerId));
        jdbcTemplate.update("INSERT INTO message(conversation_id,from_user_id,to_user_id,content,is_read,status,is_deleted) VALUES(?,?,?,?,FALSE,1,FALSE)",
                conversationId, session.userId(), peerId, "导出私信内容");
        jdbcTemplate.update("INSERT INTO user_block(user_id,blocked_user_id) VALUES(?,?)", session.userId(), peerId);
        jdbcTemplate.update("INSERT INTO message_report(reporter_user_id,target_type,target_id,reason,status) VALUES(?,2,?,'治理举报',0)",
                session.userId(), conversationId);

        MvcResult create = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-messages-export-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"modules\":[\"messages\"],\"format\":\"zip\"}"))
                .andExpect(status().isOk()).andReturn();
        MvcResult download = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download", readText(create, "/data/id"))
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk()).andReturn();
        JsonNode root = objectMapper.readTree(unzipSingleEntry(download.getResponse().getContentAsByteArray()));
        assertJsonText(root, "/modules/messages/conversations/0/id", conversationId);
        assertJsonText(root, "/modules/messages/messages/0/content", "导出私信内容");
    }

    @Test
    void shouldExportJoinedCircles() throws Exception {
        SessionFixture session = registerUser("privacy-circles@example.com", "CirclesPass1!");
        jdbcTemplate.update("INSERT INTO circle(region,name,description,member_count,post_count,sort,status,created_by,is_deleted) VALUES('EU','伦敦生活圈','隐私导出圈子',1,0,10,1,1,FALSE)");
        Long circleId = jdbcTemplate.queryForObject("SELECT id FROM circle WHERE region='EU' AND name='伦敦生活圈'", Long.class);
        jdbcTemplate.update("INSERT INTO circle_member(circle_id,user_id) VALUES(?,?)", circleId, session.userId());
        MvcResult create = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken())).header("Idempotency-Key", "privacy-circles-export-001")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"modules\":[\"circles\"],\"format\":\"zip\"}"))
                .andExpect(status().isOk()).andReturn();
        MvcResult download = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download", readText(create, "/data/id"))
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk()).andReturn();
        JsonNode root = objectMapper.readTree(unzipSingleEntry(download.getResponse().getContentAsByteArray()));
        assertJsonText(root, "/modules/circles/0/name", "伦敦生活圈");
        assertJsonText(root, "/modules/circles/0/region", "EU");
    }

    @Test
    void shouldExportFollowedTopicsWithFollowTime() throws Exception {
        SessionFixture session = registerUser("privacy-topics@example.com", "TopicsPass1!");
        jdbcTemplate.update("""
                INSERT INTO topic(region,name,post_count,follower_count,recommended,pinned_sort,status)
                VALUES('EU','隐私导出伦敦咖啡',0,1,FALSE,0,1)
                """);
        Long topicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topic WHERE region='EU' AND name='隐私导出伦敦咖啡'", Long.class);
        jdbcTemplate.update(
                "INSERT INTO topic_follow(topic_id,user_id,created_at) VALUES(?,?,?)",
                topicId, session.userId(), Timestamp.valueOf(LocalDateTime.of(2026, 7, 17, 10, 0)));

        MvcResult create = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-topics-export-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"modules\":[\"topics\"],\"format\":\"zip\"}"))
                .andExpect(status().isOk()).andReturn();
        MvcResult download = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download", readText(create, "/data/id"))
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk()).andReturn();
        JsonNode root = objectMapper.readTree(unzipSingleEntry(download.getResponse().getContentAsByteArray()));
        assertJsonText(root, "/modules/topics/0/name", "隐私导出伦敦咖啡");
        assertJsonText(root, "/modules/topics/0/region", "EU");
        assertJsonText(root, "/modules/topics/0/followedAt", "2026-07-17 10:00:00");
    }

    @Test
    void shouldExportOrdersReservationsAndFavoritesFromLandedBusinessTables() throws Exception {
        SessionFixture session = registerUser("privacy-business@example.com", "BusinessPass1!");
        jdbcTemplate.update(
                """
                INSERT INTO `order`(
                    order_no, user_id, deal_id, shop_id, region, quantity,
                    unit_price, amount, currency, pay_method, pay_status, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                "PRIVACY-ORDER-001", session.userId(), 1L, 10001L, "CN", 2,
                49.90, 99.80, "CNY", "alipay_mock", 1, 2
        );
        jdbcTemplate.update(
                """
                INSERT INTO reservation(
                    reservation_no, user_id, shop_id, region, reserve_time,
                    people_count, contact_name, contact_phone, remark, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                "PRIVACY-RESERVATION-001", session.userId(), 10001L, "CN",
                Timestamp.valueOf(LocalDateTime.of(2026, 7, 20, 18, 30)),
                4, "隐私导出用户", "13800000000", "靠窗", 1
        );
        jdbcTemplate.update(
                "INSERT INTO user_favorite(user_id, target_type, target_id) VALUES (?, ?, ?)",
                session.userId(), 1, 10001L
        );

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/privacy/export-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-business-export-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "modules": ["orders", "reservations", "favorites"],
                                  "format": "zip"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andReturn();

        String taskId = readText(createResult, "/data/id");
        MvcResult downloadResult = mockMvc.perform(get("/api/c/v1/privacy/export-tasks/{taskId}/download", taskId)
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode exportRoot = objectMapper.readTree(
                unzipSingleEntry(downloadResult.getResponse().getContentAsByteArray())
        );
        assertJsonText(exportRoot, "/modules/orders/0/orderNo", "PRIVACY-ORDER-001");
        assertJsonText(exportRoot, "/modules/orders/0/amount", 99.8);
        assertJsonText(exportRoot, "/modules/reservations/0/reservationNo", "PRIVACY-RESERVATION-001");
        assertJsonText(exportRoot, "/modules/reservations/0/contactName", "隐私导出用户");
        assertJsonText(exportRoot, "/modules/favorites/0/targetType", 1);
        assertJsonText(exportRoot, "/modules/favorites/0/targetId", 10001);
    }

    @Test
    void shouldCreateDeleteTaskAndCancelItWithinCoolingPeriod() throws Exception {
        SessionFixture session = registerUser("privacy-cancel@example.com", "CancelPass1!");
        sendCode("delete", "email", "privacy-cancel@example.com");

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/privacy/delete-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-delete-task-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "verifyType": "code",
                                  "account": "privacy-cancel@example.com",
                                  "verifyCode": "123456",
                                  "reason": "先测撤销流程"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("冷静期中"))
                .andExpect(jsonPath("$.data.coolingOffExpireAt").isNotEmpty())
                .andReturn();

        String taskId = readText(createResult, "/data/id");

        mockMvc.perform(post("/api/c/v1/privacy/delete-tasks/{taskId}/cancel", taskId)
                        .header("Authorization", bearer(session.accessToken()))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.status").value(4))
                .andExpect(jsonPath("$.data.statusText").value("已取消"));

        mockMvc.perform(get("/api/c/v1/privacy/overview")
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.latestDeleteTask.id").value(Long.parseLong(taskId)))
                .andExpect(jsonPath("$.data.latestDeleteTask.statusText").value("已取消"));
    }

    @Test
    void shouldProcessExpiredDeleteTaskAndBlockAccess() throws Exception {
        SessionFixture session = registerUser("privacy-delete@example.com", "DeletePass1!");
        jdbcTemplate.update("INSERT INTO app_user(nickname,email,preferred_region,status,is_deleted) VALUES('注销关系对端','delete-related@example.com','EU',1,FALSE)");
        Long relatedUserId = jdbcTemplate.queryForObject("SELECT id FROM app_user WHERE email='delete-related@example.com'", Long.class);
        jdbcTemplate.update("INSERT INTO user_follow(follower_user_id,followed_user_id) VALUES(?,?)", session.userId(), relatedUserId);
        jdbcTemplate.update("INSERT INTO user_follow(follower_user_id,followed_user_id) VALUES(?,?)", relatedUserId, session.userId());
        jdbcTemplate.update("INSERT INTO user_notification(user_id,actor_user_id,region,type,title,content,link_url,is_read) VALUES(?,?,'GLOBAL','social.follow','新增关注','隐私测试用户关注了你',?,FALSE)", relatedUserId, session.userId(), "/users/" + session.userId());
        jdbcTemplate.update("INSERT INTO conversation(user_a,user_b,last_message_preview,last_message_at) VALUES(?,?,?,CURRENT_TIMESTAMP)", Math.min(session.userId(), relatedUserId), Math.max(session.userId(), relatedUserId), "注销前私信");
        Long messageConversationId = jdbcTemplate.queryForObject("SELECT id FROM conversation WHERE user_a=? AND user_b=?", Long.class, Math.min(session.userId(), relatedUserId), Math.max(session.userId(), relatedUserId));
        jdbcTemplate.update("INSERT INTO message(conversation_id,from_user_id,to_user_id,content,is_read,status,is_deleted) VALUES(?,?,?,?,FALSE,1,FALSE)", messageConversationId, session.userId(), relatedUserId, "注销前私信");
        jdbcTemplate.update("INSERT INTO user_block(user_id,blocked_user_id) VALUES(?,?)", session.userId(), relatedUserId);
        jdbcTemplate.update("INSERT INTO message_report(reporter_user_id,target_type,target_id,reason,status) VALUES(?,2,?,'注销前举报',0)", session.userId(), messageConversationId);
        jdbcTemplate.update("INSERT INTO circle(region,name,description,member_count,post_count,sort,status,created_by,is_deleted) VALUES('EU','注销治理圈','治理测试',1,0,10,1,1,FALSE)");
        Long deletionCircleId = jdbcTemplate.queryForObject("SELECT id FROM circle WHERE region='EU' AND name='注销治理圈'", Long.class);
        jdbcTemplate.update("INSERT INTO circle_member(circle_id,user_id) VALUES(?,?)", deletionCircleId, session.userId());
        jdbcTemplate.update("""
                INSERT INTO topic(region,name,post_count,follower_count,recommended,pinned_sort,status)
                VALUES('EU','注销治理话题一',0,99,FALSE,0,1),('EU','注销治理话题二',0,99,FALSE,0,1)
                """);
        Long deletionTopicOne = jdbcTemplate.queryForObject("SELECT id FROM topic WHERE name='注销治理话题一'", Long.class);
        Long deletionTopicTwo = jdbcTemplate.queryForObject("SELECT id FROM topic WHERE name='注销治理话题二'", Long.class);
        jdbcTemplate.update("INSERT INTO topic_follow(topic_id,user_id) VALUES(?,?)", deletionTopicOne, session.userId());
        jdbcTemplate.update("INSERT INTO topic_follow(topic_id,user_id) VALUES(?,?)", deletionTopicTwo, session.userId());
        jdbcTemplate.update("INSERT INTO topic_follow(topic_id,user_id) VALUES(?,94001)", deletionTopicOne);
        jdbcTemplate.update("""
                INSERT INTO post(user_id,region,user_name,title,content,content_type,like_count,comment_count,repost_count,
                                 audit_status,audit_remark,status,is_deleted)
                VALUES(91002,'EU','注销转发原帖作者','注销转发治理原帖','用于验证注销清理关系',1,0,0,1,1,'',1,FALSE)
                """);
        Long deletionRepostPostId = jdbcTemplate.queryForObject(
                "SELECT id FROM post WHERE title='注销转发治理原帖'", Long.class);
        jdbcTemplate.update(
                "INSERT INTO post_repost(post_id,user_id,region) VALUES(?,?, 'EU')",
                deletionRepostPostId,
                session.userId()
        );
        jdbcTemplate.update("""
                INSERT INTO post(user_id,region,user_name,title,content,content_type,like_count,comment_count,repost_count,
                                 audit_status,audit_remark,status,is_deleted)
                VALUES(?,?,?,?,?,1,0,0,1,1,'',1,FALSE)
                """, session.userId(), "EU", "注销用户原帖", "被他人转发的原帖", "原帖内容");
        Long ownedRepostPostId = jdbcTemplate.queryForObject(
                "SELECT id FROM post WHERE title='被他人转发的原帖'", Long.class);
        jdbcTemplate.update(
                "INSERT INTO post_repost(post_id,user_id,region) VALUES(?,?, 'EU')",
                ownedRepostPostId,
                relatedUserId
        );
        jdbcTemplate.update("""
                INSERT INTO topic_hot_snapshot(topic_id,region,score,post_count_7d,like_count_7d,comment_count_7d,calculated_at)
                VALUES(?,'EU',77,1,1,1,CURRENT_TIMESTAMP)
                """, deletionTopicOne);
        MvcResult deviceResult = mockMvc.perform(post("/api/c/v1/devices/register")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-delete-device-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "deviceUid": "privacy-delete-device",
                                  "platform": 2,
                                  "pushChannel": 1,
                                  "pushToken": "fcm-delete-token",
                                  "appVersion": "1.0.0"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long deviceId = Long.parseLong(readText(deviceResult, "/data/id"));
        sendCode("delete", "email", "privacy-delete@example.com");

        MvcResult createResult = mockMvc.perform(post("/api/c/v1/privacy/delete-tasks")
                        .header("Authorization", bearer(session.accessToken()))
                        .header("Idempotency-Key", "privacy-delete-task-002")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "verifyType": "code",
                                  "account": "privacy-delete@example.com",
                                  "verifyCode": "123456",
                                  "reason": "测冷静期到点后的真实处理"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();

        long taskId = Long.parseLong(readText(createResult, "/data/id"));
        jdbcTemplate.update(
                "UPDATE privacy_delete_task SET cooling_off_expire_at = ?, updated_at = ? WHERE id = ?",
                Timestamp.valueOf(LocalDateTime.now().minusMinutes(5)),
                Timestamp.valueOf(LocalDateTime.now().minusMinutes(5)),
                taskId
        );

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(session.accessToken())))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "privacy-delete@example.com",
                                  "password": "DeletePass1!"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        Integer deleteTaskStatus = jdbcTemplate.queryForObject(
                "SELECT status FROM privacy_delete_task WHERE id = ?",
                Integer.class,
                taskId
        );
        Integer deletedUserCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM app_user WHERE id = ? AND is_deleted = TRUE AND email IS NULL AND phone IS NULL",
                Integer.class,
                session.userId()
        );
        Integer disabledDeviceCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM user_device WHERE id = ? AND status = 2 AND push_channel = 0 AND push_token = ''",
                Integer.class,
                deviceId
        );
        Integer remainingRelations = jdbcTemplate.queryForObject("SELECT COUNT(1) FROM user_follow WHERE follower_user_id=? OR followed_user_id=?", Integer.class, session.userId(), session.userId());
        Integer anonymizedSourceNotifications = jdbcTemplate.queryForObject("SELECT COUNT(1) FROM user_notification WHERE user_id=? AND actor_user_id IS NULL AND content='已注销用户曾关注了你' AND link_url=''", Integer.class, relatedUserId);
        Integer remainingBlocks = jdbcTemplate.queryForObject("SELECT COUNT(1) FROM user_block WHERE user_id=? OR blocked_user_id=?", Integer.class, session.userId(), session.userId());
        Integer governedMessages = jdbcTemplate.queryForObject("SELECT COUNT(1) FROM message WHERE conversation_id=? AND from_user_id=0 AND content='消息已因账号注销移除'", Integer.class, messageConversationId);
        Integer anonymizedReports = jdbcTemplate.queryForObject("SELECT COUNT(1) FROM message_report WHERE target_id=? AND reporter_user_id=0", Integer.class, messageConversationId);
        Integer remainingCircleMemberships = jdbcTemplate.queryForObject("SELECT COUNT(1) FROM circle_member WHERE user_id=?", Integer.class, session.userId());
        Integer governedCircleCount = jdbcTemplate.queryForObject("SELECT member_count FROM circle WHERE id=?", Integer.class, deletionCircleId);
        Integer remainingTopicFollows = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM topic_follow WHERE user_id=?", Integer.class, session.userId());
        Integer governedTopicOneCount = jdbcTemplate.queryForObject(
                "SELECT follower_count FROM topic WHERE id=?", Integer.class, deletionTopicOne);
        Integer governedTopicTwoCount = jdbcTemplate.queryForObject(
                "SELECT follower_count FROM topic WHERE id=?", Integer.class, deletionTopicTwo);
        Integer preservedTopicSnapshots = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM topic_hot_snapshot WHERE topic_id=?", Integer.class, deletionTopicOne);
        Integer remainingPostReposts = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM post_repost WHERE user_id=?", Integer.class, session.userId());
        Integer governedRepostCount = jdbcTemplate.queryForObject(
                "SELECT repost_count FROM post WHERE id=?", Integer.class, deletionRepostPostId);
        Integer remainingRepostsOnOwnedPost = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM post_repost WHERE post_id=?", Integer.class, ownedRepostPostId);
        Integer governedOwnedRepostCount = jdbcTemplate.queryForObject(
                "SELECT repost_count FROM post WHERE id=?", Integer.class, ownedRepostPostId);

        if (deleteTaskStatus == null || deleteTaskStatus != 3) {
            throw new AssertionError("删除任务没有被处理成已完成");
        }
        if (deletedUserCount == null || deletedUserCount != 1) {
            throw new AssertionError("用户没有按预期被匿名化并删除");
        }
        if (disabledDeviceCount == null || disabledDeviceCount != 1) {
            throw new AssertionError("用户注销后设备 token 没有停用");
        }
        if (remainingRelations == null || remainingRelations != 0) throw new AssertionError("用户注销后关注关系没有清理");
        if (anonymizedSourceNotifications == null || anonymizedSourceNotifications != 1) throw new AssertionError("用户注销后关注通知来源没有匿名化");
        if (remainingBlocks == null || remainingBlocks != 0) throw new AssertionError("用户注销后拉黑关系没有清理");
        if (governedMessages == null || governedMessages != 1) throw new AssertionError("用户注销后本人私信没有匿名化");
        if (anonymizedReports == null || anonymizedReports != 1) throw new AssertionError("用户注销后举报身份没有匿名化");
        if (remainingCircleMemberships == null || remainingCircleMemberships != 0) throw new AssertionError("用户注销后圈子成员关系没有清理");
        if (governedCircleCount == null || governedCircleCount != 0) throw new AssertionError("用户注销后圈子成员数没有扣减");
        if (remainingTopicFollows == null || remainingTopicFollows != 0) throw new AssertionError("用户注销后话题关注没有清理");
        if (governedTopicOneCount == null || governedTopicOneCount != 1) throw new AssertionError("话题一关注数没有按真实关系重算");
        if (governedTopicTwoCount == null || governedTopicTwoCount != 0) throw new AssertionError("话题二关注数没有按真实关系重算");
        if (preservedTopicSnapshots == null || preservedTopicSnapshots != 1) throw new AssertionError("匿名热榜快照不应按用户删除");
        if (remainingPostReposts == null || remainingPostReposts != 0) throw new AssertionError("用户注销后帖子转发关系没有清理");
        if (governedRepostCount == null || governedRepostCount != 0) throw new AssertionError("用户注销后帖子转发数没有按真实关系重算");
        if (remainingRepostsOnOwnedPost == null || remainingRepostsOnOwnedPost != 0) throw new AssertionError("用户注销后原帖上的他人转发关系没有治理");
        if (governedOwnedRepostCount == null || governedOwnedRepostCount != 0) throw new AssertionError("用户注销后原帖转发数没有重算");
    }

    private SessionFixture registerUser(String email, String password) throws Exception {
        sendCode("register", "email", email);

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "%s",
                                  "nickname": "隐私测试用户"
                                }
                                """.formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn();

        return new SessionFixture(
                readText(registerResult, "/data/accessToken"),
                Long.parseLong(readText(registerResult, "/data/user/id"))
        );
    }

    private void sendCode(String scene, String type, String account) throws Exception {
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "%s",
                                  "type": "%s",
                                  "account": "%s",
                                  "deviceId": "privacy-test-device"
                                }
                                """.formatted(scene, type, account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
    }

    private void createReview(String accessToken, long shopId, String content) throws Exception {
        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "shopId": %d,
                                  "content": "%s",
                                  "scoreOverall": 5,
                                  "scoreTaste": 5,
                                  "scoreEnv": 4,
                                  "scoreService": 5,
                                  "cost": 120.00,
                                  "currency": "CNY",
                                  "tags": ["隐私中心", "导出验证"],
                                  "images": [
                                    "https://placehold.co/800x520/f97316/ffffff?text=Privacy+Export"
                                  ]
                                }
                                """.formatted(shopId, content)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
    }

    private String unzipSingleEntry(byte[] zipBytes) throws Exception {
        try (ZipInputStream zipInputStream = new ZipInputStream(new ByteArrayInputStream(zipBytes), StandardCharsets.UTF_8)) {
            ZipEntry entry = zipInputStream.getNextEntry();
            if (entry == null) {
                throw new AssertionError("导出 ZIP 里连个文件都没有");
            }
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            zipInputStream.transferTo(outputStream);
            return outputStream.toString(StandardCharsets.UTF_8);
        }
    }

    private void assertJsonText(JsonNode root, String pointer, Object expectedValue) {
        JsonNode node = root.at(pointer);
        if (node.isMissingNode()) {
            throw new AssertionError("缺少节点: " + pointer);
        }
        String actual = node.isTextual() ? node.asText() : node.toString();
        String expected = expectedValue.toString();
        if (!expected.equals(actual)) {
            throw new AssertionError("节点 " + pointer + " 期望 " + expected + "，实际 " + actual);
        }
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }

    private record SessionFixture(String accessToken, long userId) {
    }
}
