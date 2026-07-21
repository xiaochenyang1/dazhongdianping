package com.tuowei.dazhongdianping.module.admin.auth.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
class AdminAuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void shouldKeepLoginProfileResponseContract() throws Exception {
        mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.profile.account").value("admin"))
                .andExpect(jsonPath("$.data.profile.name").value("系统管理员"))
                .andExpect(jsonPath("$.data.regions[0]").value("CN"))
                .andExpect(jsonPath("$.data.regions[1]").value("EU"))
                .andExpect(jsonPath("$.data.admin").doesNotExist());
    }

    @Test
    void shouldReturnCurrentDatabaseIdentity() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/auth/me")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.profile.account").value("admin"))
                .andExpect(jsonPath("$.data.permissions").isArray())
                .andExpect(jsonPath("$.data.regions[0]").value("CN"))
                .andExpect(jsonPath("$.data.regions[1]").value("EU"));
    }

    @Test
    void shouldInvalidateExistingTokenWhenDatabaseAdminIsDisabled() throws Exception {
        String token = loginToken();
        jdbc.update("UPDATE admin_user SET status=2 WHERE id=1");

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("管理员账号已停用"));
    }

    @Test
    void shouldLogoutAndRevokeCurrentAdminToken() throws Exception {
        String token = loginToken();

        mockMvc.perform(post("/api/admin/v1/auth/logout")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.messageKey").value("admin.logout_success"));

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldExposePostAuditMenu() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[1].code").value("audit"))
                .andExpect(jsonPath("$.data[1].children[?(@.code == 'audit.posts')].path").value("/audit/posts"));
    }

    @Test
    void shouldExposeExpertCertificationAuditMenu() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[1].children[?(@.code == 'audit.expert_certifications')].path")
                        .value("/audit/expert-certifications"));
    }

    @Test
    void shouldExposeMerchantApplicationAuditMenu() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[1].children[?(@.code == 'audit.merchant_applications')].path")
                        .value("/audit/merchant-applications"));
    }

    @Test
    void shouldExposeAuditLogSystemMenu() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[4].children[?(@.code == 'system.audit_logs')].path")
                        .value("/system/audit-logs"));
    }

    @Test
    void shouldExposePrivacyTaskSystemMenu() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[4].children[?(@.code == 'system.privacy_tasks')].path")
                        .value("/system/privacy-tasks"));
    }

    private String loginToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody()))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.path("data").path("accessToken").asText();
    }

    private String loginBody() {
        return """
                {
                  "account": "admin",
                  "password": "admin123456"
                }
                """;
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
