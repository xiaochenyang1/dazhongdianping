package com.tuowei.dazhongdianping.module.topic.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.topic.model.TopicHotSnapshotRow;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
class TopicHotRankingServiceTest {

    @Autowired private TopicHotRankingService hotRankingService;
    @Autowired private TopicHotSnapshotWriter snapshotWriter;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @BeforeEach
    @AfterEach
    void cleanTopicFixtures() {
        jdbcTemplate.update("DELETE FROM topic_hot_snapshot");
        jdbcTemplate.update("DELETE FROM topic_follow");
        jdbcTemplate.update("DELETE FROM post_topic");
        jdbcTemplate.update("DELETE FROM post_like");
        jdbcTemplate.update("DELETE FROM post_comment");
        jdbcTemplate.update("DELETE FROM post WHERE title LIKE '热榜测试%'");
        jdbcTemplate.update("DELETE FROM topic WHERE name LIKE '热榜测试%'");
    }

    @Test
    void shouldCalculateFixedSevenDayFormulaAndOrderPinnedTopics() throws Exception {
        LocalDateTime now = LocalDateTime.now();
        long hotTopic = insertTopic("EU", "热榜测试伦敦咖啡", 1, true, 0, null, 8);
        long pinnedTopic = insertTopic("EU", "热榜测试置顶话题", 1, false, 50, null, 0);
        long blockedTopic = insertTopic("EU", "热榜测试屏蔽话题", 2, false, 0, null, 0);
        long mergedTopic = insertTopic("EU", "热榜测试合并源", 2, false, 0, hotTopic, 0);
        long cnTopic = insertTopic("CN", "热榜测试北京咖啡", 1, false, 0, null, 0);

        long firstPost = insertPost("EU", "热榜测试咖啡一", 1, 1, false, now.minusDays(1));
        long secondPost = insertPost("EU", "热榜测试咖啡二", 1, 1, false, now.minusDays(2));
        long oldPost = insertPost("EU", "热榜测试旧咖啡", 1, 1, false, now.minusDays(8));
        long pendingPost = insertPost("EU", "热榜测试待审核", 0, 1, false, now.minusDays(1));
        link(firstPost, hotTopic);
        link(secondPost, hotTopic);
        link(oldPost, hotTopic);
        link(pendingPost, hotTopic);

        insertLike(firstPost, 8001, now.minusHours(3));
        insertLike(firstPost, 8002, now.minusHours(2));
        insertLike(secondPost, 8003, now.minusHours(1));
        insertLike(firstPost, 8004, now.minusDays(8));
        insertLike(pendingPost, 8005, now.minusHours(1));

        insertComment(firstPost, 8101, true, now.minusHours(4));
        insertComment(firstPost, 8102, true, now.minusHours(3));
        insertComment(secondPost, 8103, true, now.minusHours(2));
        insertComment(secondPost, 8104, true, now.minusHours(1));
        insertComment(firstPost, 8105, false, now.minusHours(1));
        insertComment(firstPost, 8106, true, now.minusDays(8));
        insertComment(pendingPost, 8107, true, now.minusHours(1));

        long pinnedPost = insertPost("EU", "热榜测试置顶帖子", 1, 1, false, now.minusDays(1));
        link(pinnedPost, pinnedTopic);
        long blockedPost = insertPost("EU", "热榜测试屏蔽帖子", 1, 1, false, now.minusDays(1));
        link(blockedPost, blockedTopic);
        long mergedPost = insertPost("EU", "热榜测试合并帖子", 1, 1, false, now.minusDays(1));
        link(mergedPost, mergedTopic);
        long cnPost = insertPost("CN", "热榜测试北京帖子", 1, 1, false, now.minusDays(1));
        link(cnPost, cnTopic);

        hotRankingService.recalculateRegion("EU");

        Snapshot hot = snapshot(hotTopic);
        assertThat(hot.postCount7d()).isEqualTo(2);
        assertThat(hot.likeCount7d()).isEqualTo(3);
        assertThat(hot.commentCount7d()).isEqualTo(4);
        assertThat(hot.score()).isEqualTo(169L);
        assertThat(snapshotCount(blockedTopic)).isZero();
        assertThat(snapshotCount(mergedTopic)).isZero();
        assertThat(snapshotCount(cnTopic)).isZero();

        mockMvc.perform(get("/api/c/v1/topics/hot").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(pinnedTopic))
                .andExpect(jsonPath("$.data.list[1].id").value(hotTopic))
                .andExpect(jsonPath("$.data.list[1].hotScore").value(169))
                .andExpect(jsonPath("$.data.list[1].postCount7d").value(2))
                .andExpect(jsonPath("$.data.list[1].likeCount7d").value(3))
                .andExpect(jsonPath("$.data.list[1].commentCount7d").value(4));
    }

    @Test
    void shouldBuildCurrentRegionSnapshotOnFirstHotRead() throws Exception {
        long topicId = insertTopic("CN", "热榜测试首次兜底", 1, false, 0, null, 0);
        long postId = insertPost("CN", "热榜测试首次兜底帖子", 1, 1, false, LocalDateTime.now().minusDays(1));
        link(postId, topicId);

        assertThat(snapshotCount(topicId)).isZero();
        mockMvc.perform(get("/api/c/v1/topics/hot").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(topicId))
                .andExpect(jsonPath("$.data.list[0].hotScore").value(20));
        assertThat(snapshot(topicId).score()).isEqualTo(20L);
    }

    @Test
    void shouldMarkTopicsDirtyAndRecalculateAfterLikeAndComment() throws Exception {
        long topicId = insertTopic("EU", "热榜测试互动刷新", 1, false, 0, null, 0);
        long postId = insertPost("EU", "热榜测试互动帖子", 1, 1, false, LocalDateTime.now().minusDays(1));
        link(postId, topicId);
        hotRankingService.recalculateRegion("EU");

        LocalDateTime old = LocalDateTime.now().minusHours(2);
        jdbcTemplate.update("UPDATE topic SET updated_at=? WHERE id=?", old, topicId);
        jdbcTemplate.update("UPDATE topic_hot_snapshot SET calculated_at=? WHERE topic_id=?", old, topicId);
        String token = registerUser();

        mockMvc.perform(post("/api/c/v1/posts/{id}/like", postId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/c/v1/posts/{id}/comments", postId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"热榜测试互动评论\"}"))
                .andExpect(status().isOk());

        LocalDateTime updatedAt = jdbcTemplate.queryForObject(
                "SELECT updated_at FROM topic WHERE id=?", LocalDateTime.class, topicId);
        assertThat(updatedAt).isAfter(old);

        hotRankingService.recalculateDirtyRegion("EU");
        Snapshot refreshed = snapshot(topicId);
        assertThat(refreshed.likeCount7d()).isEqualTo(1);
        assertThat(refreshed.commentCount7d()).isEqualTo(1);
        assertThat(refreshed.score()).isEqualTo(28L);
    }

    @Test
    void shouldRollbackSnapshotReplacementWhenInsertFails() {
        long topicId = insertTopic("EU", "热榜测试回滚", 1, false, 0, null, 0);
        jdbcTemplate.update("""
                INSERT INTO topic_hot_snapshot(topic_id,region,score,post_count_7d,like_count_7d,comment_count_7d,calculated_at)
                VALUES(?, 'EU', 88, 1, 2, 3, CURRENT_TIMESTAMP)
                """, topicId);

        TopicHotSnapshotRow invalidSnapshot = new TopicHotSnapshotRow();
        invalidSnapshot.setTopicId(null);
        invalidSnapshot.setRegion("EU");
        invalidSnapshot.setScore(999L);
        invalidSnapshot.setPostCount7d(9);
        invalidSnapshot.setLikeCount7d(9);
        invalidSnapshot.setCommentCount7d(9);
        invalidSnapshot.setCalculatedAt(LocalDateTime.now());

        assertThatThrownBy(() -> snapshotWriter.replaceTopics(Set.of(topicId), List.of(invalidSnapshot)))
                .isInstanceOf(DataIntegrityViolationException.class);
        assertThat(snapshot(topicId).score()).isEqualTo(88L);
    }

    private long insertTopic(String region, String name, int status, boolean recommended,
                             int pinnedSort, Long mergedToId, int followerCount) {
        jdbcTemplate.update("""
                INSERT INTO topic(region,name,post_count,follower_count,recommended,pinned_sort,merged_to_id,status)
                VALUES(?,?,0,?,?,?,?,?)
                """, region, name, followerCount, recommended, pinnedSort, mergedToId, status);
        return jdbcTemplate.queryForObject("SELECT id FROM topic WHERE region=? AND name=?", Long.class, region, name);
    }

    private long insertPost(String region, String title, int auditStatus, int status,
                            boolean deleted, LocalDateTime createdAt) {
        jdbcTemplate.update("""
                INSERT INTO post(user_id,region,user_name,title,content,content_type,like_count,comment_count,
                                 audit_status,audit_remark,status,is_deleted,created_at,updated_at)
                VALUES(7001,?,'热榜用户',?,'热榜测试内容',1,0,0,?,'',?,?,?,?)
                """, region, title, auditStatus, status, deleted, createdAt, createdAt);
        return jdbcTemplate.queryForObject("SELECT id FROM post WHERE title=?", Long.class, title);
    }

    private void link(long postId, long topicId) {
        jdbcTemplate.update("INSERT INTO post_topic(post_id,topic_id) VALUES(?,?)", postId, topicId);
    }

    private void insertLike(long postId, long userId, LocalDateTime createdAt) {
        jdbcTemplate.update("INSERT INTO post_like(post_id,user_id,created_at) VALUES(?,?,?)", postId, userId, createdAt);
    }

    private void insertComment(long postId, long userId, boolean visible, LocalDateTime createdAt) {
        jdbcTemplate.update("""
                INSERT INTO post_comment(post_id,user_id,user_name,content,status,is_deleted,created_at,updated_at)
                VALUES(?,?,'热榜评论者','热榜测试评论',?,?,?,?)
                """, postId, userId, visible ? 1 : 2, !visible, createdAt, createdAt);
    }

    private int snapshotCount(long topicId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM topic_hot_snapshot WHERE topic_id=?", Integer.class, topicId);
    }

    private Snapshot snapshot(long topicId) {
        return jdbcTemplate.queryForObject("""
                        SELECT score,post_count_7d,like_count_7d,comment_count_7d
                        FROM topic_hot_snapshot WHERE topic_id=?
                        """,
                (rs, rowNum) -> new Snapshot(
                        rs.getLong("score"),
                        rs.getInt("post_count_7d"),
                        rs.getInt("like_count_7d"),
                        rs.getInt("comment_count_7d")
                ), topicId);
    }

    private String registerUser() throws Exception {
        String account = "topic-hot-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> { request.setRemoteAddr("10.99.18.8"); return request; })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scene":"register","type":"email","account":"%s","deviceId":"topic-hot-test-%s"}
                                """.formatted(account, UUID.randomUUID())))
                .andExpect(status().isOk());
        MvcResult registered = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"%s","code":"123456","password":"Passw0rd!","nickname":"热榜互动用户","preferredRegion":"EU"}
                                """.formatted(account)))
                .andExpect(status().isOk())
                .andReturn();
        return readText(registered, "/data/accessToken");
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record Snapshot(long score, int postCount7d, int likeCount7d, int commentCount7d) {}
}
