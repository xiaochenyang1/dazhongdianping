package com.tuowei.dazhongdianping.module.admin.audit;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.hamcrest.Matchers.nullValue;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminAuditLogControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void seedAuditLogs() {
        jdbc.update(
                "INSERT INTO admin_user(id,account,password_hash,name,status) VALUES (88,?,?,?,1)",
                "ops.eu",
                new BCryptPasswordEncoder().encode("ops123456"),
                "EU 运营管理员"
        );
        jdbc.update(
                """
                INSERT INTO audit_log(id,admin_id,action,target,detail,ip,created_at) VALUES
                (9001,1,'admin.login_success','admin:1','后台登录成功','127.0.0.1',TIMESTAMP '2026-07-19 09:00:00'),
                (9002,1,'system.role_update','role:7','更新 EU 只读员权限','127.0.0.2',TIMESTAMP '2026-07-19 10:00:00'),
                (9003,88,'audit_review_pass','review:5','通过点评审核','10.8.0.6',TIMESTAMP '2026-07-19 11:00:00')
                """
        );
    }

    @Test
    void shouldListAuditLogsInReverseChronologicalOrder() throws Exception {
        String token = login("admin", "admin123456");
        jdbc.update("DELETE FROM audit_log WHERE id NOT IN (9001, 9002, 9003)");

        mockMvc.perform(get("/api/admin/v1/audit/logs")
                        .header("Authorization", bearer(token))
                        .param("page", "1")
                        .param("pageSize", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(3))
                .andExpect(jsonPath("$.data.hasMore").value(true))
                .andExpect(jsonPath("$.data.list[0].id").value(9003))
                .andExpect(jsonPath("$.data.list[0].adminAccount").value("ops.eu"))
                .andExpect(jsonPath("$.data.list[0].action").value("audit_review_pass"))
                .andExpect(jsonPath("$.data.list[1].id").value(9002))
                .andExpect(jsonPath("$.data.list[1].target").value("role:7"));
    }

    @Test
    void shouldFilterAuditLogsByAdminActionAndKeyword() throws Exception {
        mockMvc.perform(get("/api/admin/v1/audit/logs")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .param("adminId", "1")
                        .param("action", "system.role_update")
                        .param("keyword", "只读员"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(9002))
                .andExpect(jsonPath("$.data.list[0].adminName").value("系统管理员"))
                .andExpect(jsonPath("$.data.list[0].detail").value("更新 EU 只读员权限"));
    }

    @Test
    void shouldReportRegionScopedQueueMetricsAndOldestPendingTaskFirst() throws Exception {
        jdbc.update("DELETE FROM audit_task WHERE biz_type BETWEEN 10 AND 14");
        jdbc.update("""
                INSERT INTO audit_task(id,biz_type,biz_id,region,machine_result,status,auditor_id,remark,created_at,updated_at) VALUES
                (9301,10,1,'CN',2,0,0,'待复核','2026-10-11 08:00:00','2026-10-11 08:00:00'),
                (9302,10,2,'CN',2,0,0,'待复核','2026-10-11 07:00:00','2026-10-11 07:00:00'),
                (9303,10,3,'CN',2,1,1,'人工通过','2026-10-10 08:00:00','2026-10-10 09:00:00'),
                (9304,10,4,'CN',2,2,0,'父内容删除导致失效','2026-10-10 01:00:00','2026-10-11 07:00:00'),
                (9401,10,5,'EU',2,0,0,'其他区域','2026-10-09 07:00:00','2026-10-09 07:00:00')
                """);
        String token = login("admin", "admin123456");

        mockMvc.perform(get("/api/admin/v1/audit/tasks/metrics")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(5))
                .andExpect(jsonPath("$.data[0].bizType").value(10))
                .andExpect(jsonPath("$.data[0].pendingCount").value(2))
                .andExpect(jsonPath("$.data[0].oldestPendingAt").value("2026-10-11 07:00:00"))
                .andExpect(jsonPath("$.data[0].processedCount").value(1))
                .andExpect(jsonPath("$.data[0].averageProcessingSeconds").value(3600));

        mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(token))
                        .param("bizType", "10")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].bizId").value(2))
                .andExpect(jsonPath("$.data.list[1].bizId").value(1));
    }

    @Test
    void shouldClaimReleaseFilterAndTakeOverExpiredModerationTasks() throws Exception {
        jdbc.update("DELETE FROM audit_task WHERE biz_type BETWEEN 10 AND 14");
        jdbc.update("""
                INSERT INTO audit_task(id,biz_type,biz_id,region,machine_result,status,auditor_id,remark,created_at,updated_at)
                VALUES (9501,10,51,'CN',2,0,0,'待复核',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
                """);
        String token = login("admin", "admin123456");

        mockMvc.perform(post("/api/admin/v1/audit/tasks/9501/claim")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.claimedByAdminId").value(1))
                .andExpect(jsonPath("$.data.claimedByAdminName").value("系统管理员"))
                .andExpect(jsonPath("$.data.claimExpiresAt").isNotEmpty());

        mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(token))
                        .param("bizType", "10")
                        .param("status", "0")
                        .param("assignmentFilter", "mine"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1));

        mockMvc.perform(post("/api/admin/v1/audit/tasks/9501/release")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.claimedByAdminId").value(nullValue()));

        LocalDateTime now = LocalDateTime.now();
        jdbc.update("UPDATE audit_task SET claimed_by_admin_id=?,claimed_at=?,claim_expires_at=? WHERE id=?",
                88L, now, now.plusMinutes(15), 9501L);
        mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(token))
                        .param("bizType", "10")
                        .param("status", "0")
                        .param("assignmentFilter", "others"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1));

        mockMvc.perform(post("/api/admin/v1/audit/tasks/9501/release")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isConflict());
        mockMvc.perform(post("/api/admin/v1/audit/tasks/9501/pass")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isConflict());

        mockMvc.perform(post("/api/admin/v1/audit/tasks/9501/claim")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isConflict());

        jdbc.update("UPDATE audit_task SET claim_expires_at=? WHERE id=?", now.minusMinutes(1), 9501L);
        mockMvc.perform(post("/api/admin/v1/audit/tasks/9501/claim")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.claimedByAdminId").value(1));
    }

    private String login(String account, String password) throws Exception {
        var result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"%s","password":"%s"}
                                """.formatted(account, password)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
