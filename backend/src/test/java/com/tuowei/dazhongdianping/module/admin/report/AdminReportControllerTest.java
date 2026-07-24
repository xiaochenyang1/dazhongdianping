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
