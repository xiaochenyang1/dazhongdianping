package com.tuowei.dazhongdianping.module.admin.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.auth.service.SendCodeRateLimitService;
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
class AdminAppUserControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private SendCodeRateLimitService sendCodeRateLimitService;

    @BeforeEach
    void resetState() {
        sendCodeRateLimitService.clearAll();
    }

    @Test
    void shouldListUsersWithFilters() throws Exception {
        String adminToken = adminLogin();

        mockMvc.perform(get("/api/admin/v1/users")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].id").value(9002))
                .andExpect(jsonPath("$.data.list[0].statusText").value("正常"))
                .andExpect(jsonPath("$.data.list[1].id").value(9001));

        mockMvc.perform(get("/api/admin/v1/users")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("keyword", "咖啡"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(9002))
                .andExpect(jsonPath("$.data.list[0].nickname").value("欧洲咖啡客"));

        mockMvc.perform(get("/api/admin/v1/users")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("preferredRegion", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(9002));

        mockMvc.perform(get("/api/admin/v1/users")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("keyword", "demo.cn@example.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(9001));
    }

    @Test
    void shouldReturnUserDetailWithContentStats() throws Exception {
        String adminToken = adminLogin();
        SessionFixture user = registerUser("governance-detail@example.com", "GovPass123!");
        createReview(user.accessToken(), 10001L, "用户治理详情统计测试点评，内容长度必须要够。");

        mockMvc.perform(get("/api/admin/v1/users/{userId}", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").value(user.userId()))
                .andExpect(jsonPath("$.data.email").value("governance-detail@example.com"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("正常"))
                .andExpect(jsonPath("$.data.reviewCount").value(1))
                .andExpect(jsonPath("$.data.postCount").value(0))
                .andExpect(jsonPath("$.data.activeSessionCount").value(1));

        mockMvc.perform(get("/api/admin/v1/users/{userId}", 999999)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldBanUserRevokeSessionsAndBlockLoginsThenUnban() throws Exception {
        String adminToken = adminLogin();
        SessionFixture user = registerUser("governance-ban@example.com", "GovBan123!");

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(user.accessToken())))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"ban","reason":"发布垃圾广告"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.statusText").value("已封禁"));

        Integer auditCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE action = 'user_ban' AND target = ?",
                Integer.class,
                "app_user:" + user.userId()
        );
        assertThat(auditCount).isEqualTo(1);

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(user.accessToken())))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"governance-ban@example.com","password":"GovBan123!"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("账号已被封禁，暂时无法登录"));

        sendCode("login", "email", "governance-ban@example.com");
        mockMvc.perform(post("/api/c/v1/auth/login/code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"governance-ban@example.com","code":"123456"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("账号已被封禁，暂时无法登录"));

        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"unban","reason":"申诉通过"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("正常"));

        Integer unbanAuditCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE action = 'user_unban' AND target = ?",
                Integer.class,
                "app_user:" + user.userId()
        );
        assertThat(unbanAuditCount).isEqualTo(1);

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"governance-ban@example.com","password":"GovBan123!"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
    }

    @Test
    void shouldRejectInvalidStatusChanges() throws Exception {
        String adminToken = adminLogin();
        SessionFixture user = registerUser("governance-invalid@example.com", "GovInv123!");

        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"ban","reason":"  "}
                                """))
                .andExpect(status().isBadRequest());

        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"unban"}
                                """))
                .andExpect(status().isBadRequest());

        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"freeze","reason":"不存在的动作"}
                                """))
                .andExpect(status().isBadRequest());

        jdbc.update("UPDATE app_user SET is_deleted = TRUE WHERE id = ?", user.userId());
        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"ban","reason":"已注销用户"}
                                """))
                .andExpect(status().isBadRequest());

        mockMvc.perform(get("/api/admin/v1/users")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("status", "3")
                        .param("userId", String.valueOf(user.userId())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].statusText").value("已注销"));
    }

    private String adminLogin() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"admin","password":"admin123456"}
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return readText(result, "/data/accessToken");
    }

    private SessionFixture registerUser(String email, String password) throws Exception {
        sendCode("register", "email", email);
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "%s",
                                  "nickname": "用户治理测试用户"
                                }
                                """.formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn();
        return new SessionFixture(
                readText(result, "/data/accessToken"),
                Long.parseLong(readText(result, "/data/user/id"))
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
                                  "deviceId": "admin-user-governance-test"
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
                                  "scoreEnv": 5,
                                  "scoreService": 5,
                                  "cost": 88.00,
                                  "currency": "CNY"
                                }
                                """.formatted(shopId, content)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at(pointer)
                .asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record SessionFixture(String accessToken, long userId) {
    }
}
