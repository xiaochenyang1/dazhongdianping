package com.tuowei.dazhongdianping.module.admin.report;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
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
class AdminReportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void shouldListAndResolveReviewReports() throws Exception {
        String adminToken = loginAdmin();
        String userToken = registerUser();

        // create a public-ish review first via API then force audit pass + report
        MvcResult created = mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{"
                                + "\"shopId\":10001,"
                                + "\"content\":\"这条点评会被举报处理\","
                                + "\"scoreOverall\":4.0,"
                                + "\"scoreTaste\":4.0,"
                                + "\"scoreEnv\":4.0,"
                                + "\"scoreService\":4.0,"
                                + "\"cost\":50.00,"
                                + "\"currency\":\"CNY\","
                                + "\"tags\":[\"测试\"],"
                                + "\"images\":[]"
                                + "}"))
                .andExpect(status().isOk())
                .andReturn();
        long reviewId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();
        jdbc.update("UPDATE review SET audit_status=1 WHERE id=?", reviewId);

        mockMvc.perform(post("/api/c/v1/reviews/{id}/report", reviewId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"广告引流\"}"))
                .andExpect(status().isOk());

        Long reportId = jdbc.queryForObject(
                "SELECT id FROM review_report WHERE review_id=? ORDER BY id DESC LIMIT 1",
                Long.class,
                reviewId
        );

        mockMvc.perform(get("/api/admin/v1/audit/reports")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("reportType", "review")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.list[0].reportType").value("review"));

        mockMvc.perform(post("/api/admin/v1/audit/reports/review/{id}/resolve", reportId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"hide\",\"remark\":\"确认违规广告\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("已成立"));

        Integer auditStatus = jdbc.queryForObject(
                "SELECT audit_status FROM review WHERE id=?",
                Integer.class,
                reviewId
        );
        org.junit.jupiter.api.Assertions.assertEquals(2, auditStatus);

        // dismiss path with a second report on another review content is enough via message report
        jdbc.update(
                "INSERT INTO message_report(reporter_user_id,target_type,target_id,reason,status) VALUES(?,?,?,?,0)",
                9001L,
                2,
                1L,
                "骚扰私信"
        );
        Long messageReportId = jdbc.queryForObject(
                "SELECT id FROM message_report WHERE reason='骚扰私信' ORDER BY id DESC LIMIT 1",
                Long.class
        );
        mockMvc.perform(post("/api/admin/v1/audit/reports/message/{id}/resolve", messageReportId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"dismiss\",\"remark\":\"证据不足\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));
    }

    @Test
    void shouldListAndHideReportedCommentThreads() throws Exception {
        String adminToken = loginAdmin();
        jdbc.update("""
                INSERT INTO review_comment(id,review_id,user_id,user_name,content,parent_id,reply_to,status,is_deleted)
                VALUES(99001,1,9001,'评论作者','需要治理的点评评论',0,0,1,FALSE),
                      (99002,1,9002,'回复作者','跟随根评论的楼中回复',99001,99001,1,FALSE)
                """);
        jdbc.update("UPDATE review SET comment_count=(SELECT COUNT(1) FROM review_comment WHERE review_id=1 AND status=1 AND is_deleted=FALSE) WHERE id=1");
        jdbc.update("""
                INSERT INTO review_comment_report(review_id,comment_id,reporter_user_id,reporter_user_name,reason,status,is_deleted)
                VALUES(1,99001,9003,'举报人甲','根评论广告引流',0,FALSE),
                      (1,99002,9004,'举报人乙','楼中回复骚扰',0,FALSE)
                """);
        Long reviewCommentReportId = jdbc.queryForObject(
                "SELECT id FROM review_comment_report WHERE comment_id=99001",
                Long.class
        );

        mockMvc.perform(get("/api/admin/v1/audit/reports")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("reportType", "review_comment")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].reportType").value("review_comment"));

        mockMvc.perform(post("/api/admin/v1/audit/reports/review_comment/{id}/resolve", reviewCommentReportId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"hide\",\"remark\":\"确认评论违规\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.targetStatusText").value("已隐藏"));
        org.junit.jupiter.api.Assertions.assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM review_comment WHERE id IN (99001,99002) AND status=2",
                Integer.class
        ));
        org.junit.jupiter.api.Assertions.assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM review_comment_report WHERE comment_id IN (99001,99002) AND status=1",
                Integer.class
        ));
        org.junit.jupiter.api.Assertions.assertEquals(
                jdbc.queryForObject(
                        "SELECT COUNT(1) FROM review_comment WHERE review_id=1 AND status=1 AND is_deleted=FALSE",
                        Integer.class
                ),
                jdbc.queryForObject("SELECT comment_count FROM review WHERE id=1", Integer.class)
        );

        jdbc.update("""
                INSERT INTO post(id,user_id,region,user_name,title,content,audit_status,status,is_deleted)
                VALUES(99001,9001,'CN','帖子作者','评论治理测试帖','用于管理端评论治理回归。',1,1,FALSE)
                """);
        jdbc.update("""
                INSERT INTO post_comment(id,post_id,user_id,user_name,content,parent_id,reply_to,status,is_deleted)
                VALUES(99101,99001,9001,'评论作者','需要治理的帖子评论',0,0,1,FALSE),
                      (99102,99001,9002,'回复作者','跟随根评论的楼中回复',99101,99101,1,FALSE)
                """);
        jdbc.update("UPDATE post SET comment_count=2 WHERE id=99001");
        jdbc.update("""
                INSERT INTO post_comment_report(post_id,comment_id,reporter_user_id,reporter_user_name,reason,status,is_deleted)
                VALUES(99001,99101,9003,'举报人甲','根评论骚扰',0,FALSE),
                      (99001,99102,9004,'举报人乙','楼中回复骚扰',0,FALSE)
                """);
        Long postCommentReportId = jdbc.queryForObject(
                "SELECT id FROM post_comment_report WHERE comment_id=99101",
                Long.class
        );

        mockMvc.perform(post("/api/admin/v1/audit/reports/post_comment/{id}/resolve", postCommentReportId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"hide\",\"remark\":\"确认评论违规\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.targetStatusText").value("已隐藏"));
        org.junit.jupiter.api.Assertions.assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM post_comment WHERE id IN (99101,99102) AND status=2",
                Integer.class
        ));
        org.junit.jupiter.api.Assertions.assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM post_comment_report WHERE comment_id IN (99101,99102) AND status=1",
                Integer.class
        ));
        org.junit.jupiter.api.Assertions.assertEquals(0, jdbc.queryForObject(
                "SELECT comment_count FROM post WHERE id=99001",
                Integer.class
        ));
    }

    private String loginAdmin() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String registerUser() throws Exception {
        String account = "report-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"report-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
