package com.tuowei.dazhongdianping.module.admin.auth.controller;

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
class AdminPermissionControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void seedRestrictedAdmin() {
        jdbc.update("INSERT INTO admin_user(id,account,password_hash,name,status) VALUES (99,?,?,?,1)",
                "content.eu", new BCryptPasswordEncoder().encode("content123"), "EU 内容审核员");
        jdbc.update("INSERT INTO admin_role(id,code,name,description,status,built_in) VALUES (99,?,?,?,?,FALSE)",
                "review_reader", "点评只读审核员", "只能查看点评审核", 1);
        jdbc.update("INSERT INTO admin_user_role(admin_id,role_id) VALUES (99,99)");
        jdbc.update("INSERT INTO admin_role_permission(role_id,permission_id) VALUES (99,2)");
        jdbc.update("INSERT INTO admin_region_scope(admin_id,region) VALUES (99,'EU')");
    }

    @Test
    void shouldFilterMenusAndRejectMissingPermission() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/menus").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'data')]").isEmpty())
                .andExpect(jsonPath("$.data[0].children[0].code").value("audit.reviews"));

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("没有权限执行该操作"));
    }

    @Test
    void shouldRejectRegionOutsideAdminScope() throws Exception {
        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("Authorization", bearer(loginToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("当前管理员无权操作该区域"));
    }

    @Test
    void shouldHideAuditTypesWithoutReadPermission() throws Exception {
        jdbc.update("INSERT INTO audit_task(id,biz_type,biz_id,region,machine_result,status,auditor_id,remark) "
                        + "VALUES (9901,4,10001,'EU',0,0,0,'待审帖子')");

        mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(loginToken()))
                        .header("X-Region", "EU")
                        .param("bizType", "4"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0))
                .andExpect(jsonPath("$.data.list").isEmpty());
    }

    @Test
    void shouldRejectAuditDecisionWithoutBusinessTypeWritePermission() throws Exception {
        jdbc.update("INSERT INTO audit_task(id,biz_type,biz_id,region,machine_result,status,auditor_id,remark) "
                        + "VALUES (9902,4,10002,'EU',0,0,0,'待审帖子')");

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", 9902L)
                        .header("Authorization", bearer(loginToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("没有权限执行该操作"));
    }

    @Test
    void shouldRejectAuditLogQueryWithoutSystemPermission() throws Exception {
        jdbc.update("INSERT INTO audit_log(id,admin_id,action,target,detail,ip) VALUES (9903,1,'admin.login_success','admin:1','后台登录成功','127.0.0.1')");

        mockMvc.perform(get("/api/admin/v1/audit/logs")
                        .header("Authorization", bearer(loginToken())))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("没有权限执行该操作"));
    }

    private String loginToken() throws Exception {
        var result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"content.eu\",\"password\":\"content123\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken").asText();
    }

    private String bearer(String token) { return "Bearer " + token; }
}
