package com.tuowei.dazhongdianping.module.admin.audit;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
