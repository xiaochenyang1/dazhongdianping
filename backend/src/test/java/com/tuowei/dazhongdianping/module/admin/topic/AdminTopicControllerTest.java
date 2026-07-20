package com.tuowei.dazhongdianping.module.admin.topic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
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
class AdminTopicControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldFilterRenameRecommendPinBlockAndRecalculateWithinCurrentRegion() throws Exception {
        String token = loginToken();
        long euTopic = insertTopic("EU", "管理测试伦敦咖啡", 1, false, 0, null);
        insertTopic("CN", "管理测试上海咖啡", 1, false, 0, null);
        long postId = insertPost("EU", "管理测试热榜帖子");
        link(postId, euTopic);

        mockMvc.perform(get("/api/admin/v1/topics")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .param("status", "1").param("recommended", "false").param("keyword", "伦敦"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(euTopic));

        mockMvc.perform(put("/api/admin/v1/topics/{id}", euTopic)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"管理测试英国咖啡\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("管理测试英国咖啡"));

        mockMvc.perform(put("/api/admin/v1/topics/{id}/recommendation", euTopic)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"recommended\":true,\"pinnedSort\":60}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.recommended").value(true))
                .andExpect(jsonPath("$.data.pinnedSort").value(60))
                .andExpect(jsonPath("$.data.hotScore").value(120));

        mockMvc.perform(post("/api/admin/v1/topics/recalculate-hot")
                        .header("Authorization", bearer(token)).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.region").value("EU"));

        mockMvc.perform(put("/api/admin/v1/topics/{id}/status", euTopic)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM topic_hot_snapshot WHERE topic_id=?", Integer.class, euTopic)).isZero();
    }

    @Test
    void shouldRejectDuplicateRenameAndCrossRegionMutation() throws Exception {
        String token = loginToken();
        long first = insertTopic("EU", "管理测试同名一", 1, false, 0, null);
        insertTopic("EU", "管理测试同名二", 1, false, 0, null);
        long cnTopic = insertTopic("CN", "管理测试跨区", 1, false, 0, null);

        mockMvc.perform(put("/api/admin/v1/topics/{id}", first)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"管理测试同名二\"}"))
                .andExpect(status().isConflict());

        mockMvc.perform(put("/api/admin/v1/topics/{id}/status", cnTopic)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldMergePostAndFollowRelationsWithoutDuplicates() throws Exception {
        String token = loginToken();
        long target = insertTopic("EU", "管理测试合并目标", 1, false, 0, null);
        long source = insertTopic("EU", "管理测试合并来源", 1, true, 20, null);
        long sharedPost = insertPost("EU", "管理测试共同帖子");
        long sourcePost = insertPost("EU", "管理测试来源帖子");
        link(sharedPost, target);
        link(sharedPost, source);
        link(sourcePost, source);
        follow(target, 92001);
        follow(source, 92001);
        follow(source, 92002);
        jdbcTemplate.update("UPDATE topic SET post_count=99,follower_count=99 WHERE id IN (?,?)", source, target);
        insertSnapshot(target, 10);
        insertSnapshot(source, 999);

        mockMvc.perform(post("/api/admin/v1/topics/{id}/merge", source)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"targetTopicId\":" + target + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(target))
                .andExpect(jsonPath("$.data.postCount").value(2))
                .andExpect(jsonPath("$.data.followerCount").value(2))
                .andExpect(jsonPath("$.data.hotScore").value(40));

        assertThat(count("SELECT COUNT(1) FROM post_topic WHERE topic_id=?", target)).isEqualTo(2);
        assertThat(count("SELECT COUNT(1) FROM post_topic WHERE topic_id=?", source)).isZero();
        assertThat(count("SELECT COUNT(1) FROM topic_follow WHERE topic_id=?", target)).isEqualTo(2);
        assertThat(count("SELECT COUNT(1) FROM topic_follow WHERE topic_id=?", source)).isZero();
        assertThat(jdbcTemplate.queryForObject("SELECT merged_to_id FROM topic WHERE id=?", Long.class, source))
                .isEqualTo(target);
        assertThat(jdbcTemplate.queryForObject("SELECT status FROM topic WHERE id=?", Integer.class, source))
                .isEqualTo(2);
        assertThat(count("SELECT COUNT(1) FROM topic_hot_snapshot WHERE topic_id=?", source)).isZero();
    }

    @Test
    void shouldRejectInvalidMergeTargets() throws Exception {
        String token = loginToken();
        long source = insertTopic("EU", "管理测试非法来源", 1, false, 0, null);
        long cnTarget = insertTopic("CN", "管理测试跨区目标", 1, false, 0, null);
        long finalTarget = insertTopic("EU", "管理测试最终目标", 1, false, 0, null);
        long mergedTarget = insertTopic("EU", "管理测试已合并目标", 2, false, 0, finalTarget);

        merge(token, source, source).andExpect(status().isBadRequest());
        merge(token, source, cnTarget).andExpect(status().isBadRequest());
        merge(token, source, mergedTarget).andExpect(status().isBadRequest());
    }

    @Test
    void shouldExposeTopicPermissionsAndManagementMenu() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:topic:read')]").exists())
                .andExpect(jsonPath("$.data.permissions[?(@ == 'operations:topic:write')]").exists())
                .andReturn();
        String token = objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();

        mockMvc.perform(get("/api/admin/v1/menus").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[3].children[3].path").value("/operations/topics"));
    }

    private org.springframework.test.web.servlet.ResultActions merge(String token, long source, long target) throws Exception {
        return mockMvc.perform(post("/api/admin/v1/topics/{id}/merge", source)
                .header("Authorization", bearer(token)).header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"targetTopicId\":" + target + "}"));
    }

    private long insertTopic(String region, String name, int status, boolean recommended,
                             int pinnedSort, Long mergedToId) {
        jdbcTemplate.update("""
                INSERT INTO topic(region,name,post_count,follower_count,recommended,pinned_sort,merged_to_id,status)
                VALUES(?,?,0,0,?,?,?,?)
                """, region, name, recommended, pinnedSort, mergedToId, status);
        return jdbcTemplate.queryForObject("SELECT id FROM topic WHERE region=? AND name=?", Long.class, region, name);
    }

    private long insertPost(String region, String title) {
        jdbcTemplate.update("""
                INSERT INTO post(user_id,region,user_name,title,content,content_type,like_count,comment_count,
                                 audit_status,audit_remark,status,is_deleted,created_at,updated_at)
                VALUES(93001,?,'管理测试用户',?,'管理测试内容',1,0,0,1,'',1,FALSE,?,?)
                """, region, title, LocalDateTime.now().minusDays(1), LocalDateTime.now().minusDays(1));
        return jdbcTemplate.queryForObject("SELECT id FROM post WHERE title=?", Long.class, title);
    }

    private void link(long postId, long topicId) {
        jdbcTemplate.update("INSERT INTO post_topic(post_id,topic_id) VALUES(?,?)", postId, topicId);
    }

    private void follow(long topicId, long userId) {
        jdbcTemplate.update("INSERT INTO topic_follow(topic_id,user_id) VALUES(?,?)", topicId, userId);
    }

    private void insertSnapshot(long topicId, long score) {
        jdbcTemplate.update("""
                INSERT INTO topic_hot_snapshot(topic_id,region,score,post_count_7d,like_count_7d,comment_count_7d,calculated_at)
                VALUES(?,'EU',?,0,0,0,CURRENT_TIMESTAMP)
                """, topicId, score);
    }

    private int count(String sql, long id) {
        return jdbcTemplate.queryForObject(sql, Integer.class, id);
    }

    private String loginToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
