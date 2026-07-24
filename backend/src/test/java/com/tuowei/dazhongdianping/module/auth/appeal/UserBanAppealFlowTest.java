package com.tuowei.dazhongdianping.module.auth.appeal;

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
class UserBanAppealFlowTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private SendCodeRateLimitService sendCodeRateLimitService;

    @BeforeEach
    void resetState() {
        sendCodeRateLimitService.clearAll();
    }

    @Test
    void shouldCompleteAppealApproveChainAndRestoreLogin() throws Exception {
        String adminToken = adminLogin();
        SessionFixture user = registerUser("appeal-approve@example.com", "Appeal123!");
        banUser(adminToken, user.userId(), "发布违规内容");

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"appeal-approve@example.com","password":"Appeal123!"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.messageKey").value("auth.user_banned"))
                .andExpect(jsonPath("$.message").value("账号已被封禁，暂时无法登录"));

        sendAppealCode("appeal-approve@example.com");
        MvcResult submitResult = mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-approve@example.com",
                                  "code": "123456",
                                  "reason": "账号被误封，我发布的内容没有违反社区规范，请重新核实。"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(jsonPath("$.data.statusText").value("待审核"))
                .andExpect(jsonPath("$.data.banReason").value("发布违规内容"))
                .andReturn();
        long appealId = Long.parseLong(readText(submitResult, "/data/id"));

        mockMvc.perform(get("/api/admin/v1/users/{userId}", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.banReason").value("发布违规内容"))
                .andExpect(jsonPath("$.data.pendingAppealCount").value(1))
                .andExpect(jsonPath("$.data.latestAppealStatusText").value("待审核"));

        sendAppealCode("appeal-approve@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-approve@example.com",
                                  "code": "123456",
                                  "reason": "重复提交的申诉应该被拦截，不允许排队占位。"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("已有申诉正在处理中，请耐心等待审核结果"));

        MvcResult taskListResult = mockMvc.perform(get("/api/admin/v1/audit/tasks")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .param("bizType", "8")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].bizType").value(8))
                .andExpect(jsonPath("$.data.list[0].bizTypeText").value("用户封禁申诉"))
                .andExpect(jsonPath("$.data.list[0].bizId").value(appealId))
                .andExpect(jsonPath("$.data.list[0].submittedBy").value("封禁申诉测试用户"))
                .andExpect(jsonPath("$.data.list[0].summary").value("账号被误封，我发布的内容没有违反社区规范，请重新核实。"))
                .andReturn();
        long taskId = Long.parseLong(readText(taskListResult, "/data/list/0/id"));

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"remark":"核实后确认误封"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("通过"));

        Integer userStatus = jdbc.queryForObject(
                "SELECT status FROM app_user WHERE id = ?", Integer.class, user.userId());
        assertThat(userStatus).isEqualTo(1);

        Integer appealStatus = jdbc.queryForObject(
                "SELECT status FROM user_ban_appeal WHERE id = ?", Integer.class, appealId);
        assertThat(appealStatus).isEqualTo(1);

        Integer auditLogCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE action = 'audit_user_appeal_pass' AND target = ?",
                Integer.class,
                "user_appeal:" + appealId
        );
        assertThat(auditLogCount).isEqualTo(1);

        Integer approveNotificationCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM user_notification WHERE user_id = ? AND type = 'account.ban_appeal' AND title = '封禁申诉已通过'",
                Integer.class,
                user.userId()
        );
        assertThat(approveNotificationCount).isEqualTo(1);

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"appeal-approve@example.com","password":"Appeal123!"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        sendAppealCode("appeal-approve@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals/query")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"appeal-approve@example.com","code":"123456"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(appealId))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("已通过"));
    }

    @Test
    void shouldRejectAppealKeepBanAndAllowResubmit() throws Exception {
        String adminToken = adminLogin();
        SessionFixture user = registerUser("appeal-reject@example.com", "Appeal123!");
        banUser(adminToken, user.userId(), "刷单行为");

        sendAppealCode("appeal-reject@example.com");
        MvcResult submitResult = mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-reject@example.com",
                                  "code": "123456",
                                  "reason": "我认为刷单判定有误，请人工复核我的历史订单记录。"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long appealId = Long.parseLong(readText(submitResult, "/data/id"));
        long taskId = pendingTaskId(appealId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/reject", taskId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"reason":"证据充分，维持封禁"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.statusText").value("驳回"));

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"appeal-reject@example.com","password":"Appeal123!"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.messageKey").value("auth.user_banned"));

        sendAppealCode("appeal-reject@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals/query")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"appeal-reject@example.com","code":"123456"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.statusText").value("已驳回"))
                .andExpect(jsonPath("$.data.rejectReason").value("证据充分，维持封禁"))
                .andExpect(jsonPath("$.data.banReason").value("刷单行为"));

        Integer rejectLogCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_log WHERE action = 'audit_user_appeal_reject' AND target = ?",
                Integer.class,
                "user_appeal:" + appealId
        );
        assertThat(rejectLogCount).isEqualTo(1);

        String rejectNotificationContent = jdbc.queryForObject(
                "SELECT content FROM user_notification WHERE user_id = ? AND type = 'account.ban_appeal' AND title = '封禁申诉已驳回'",
                String.class,
                user.userId()
        );
        assertThat(rejectNotificationContent).contains("证据充分，维持封禁");

        sendAppealCode("appeal-reject@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-reject@example.com",
                                  "code": "123456",
                                  "reason": "补充新的证据材料，申请再次复核封禁决定。"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0));
    }

    @Test
    void shouldResolvePendingAppealWhenAdminUnbansDirectly() throws Exception {
        String adminToken = adminLogin();
        SessionFixture user = registerUser("appeal-manual@example.com", "Appeal123!");
        banUser(adminToken, user.userId(), "误报处理");

        sendAppealCode("appeal-manual@example.com");
        MvcResult submitResult = mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-manual@example.com",
                                  "code": "123456",
                                  "reason": "被误封的账号申请尽快解除限制，恢复正常使用。"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long appealId = Long.parseLong(readText(submitResult, "/data/id"));
        long taskId = pendingTaskId(appealId);

        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", user.userId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"unban","reason":"人工复核后直接解封"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        Integer appealStatus = jdbc.queryForObject(
                "SELECT status FROM user_ban_appeal WHERE id = ?", Integer.class, appealId);
        assertThat(appealStatus).isEqualTo(1);

        Integer taskStatus = jdbc.queryForObject(
                "SELECT status FROM audit_task WHERE id = ?", Integer.class, taskId);
        assertThat(taskStatus).isEqualTo(2);

        String taskRemark = jdbc.queryForObject(
                "SELECT remark FROM audit_task WHERE id = ?", String.class, taskId);
        assertThat(taskRemark).isEqualTo("任务失效：管理员已直接解封");

        Integer unbanNotificationCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM user_notification WHERE user_id = ? AND type = 'account.ban_appeal' AND title = '账号已解封'",
                Integer.class,
                user.userId()
        );
        assertThat(unbanNotificationCount).isEqualTo(1);

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"appeal-manual@example.com","password":"Appeal123!"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
    }

    @Test
    void shouldRejectInvalidAppealSubmissions() throws Exception {
        String adminToken = adminLogin();
        SessionFixture activeUser = registerUser("appeal-active@example.com", "Appeal123!");

        sendAppealCode("appeal-active@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-active@example.com",
                                  "code": "123456",
                                  "reason": "正常账号提交申诉应该被拦截并给出提示。"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("账号未被封禁，无需申诉"));

        banUser(adminToken, activeUser.userId(), "测试封禁");

        mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-active@example.com",
                                  "code": "999999",
                                  "reason": "验证码不对的申诉不能进入待审核队列。"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("验证码无效或已过期"));

        sendAppealCode("appeal-active@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-active@example.com",
                                  "code": "123456",
                                  "reason": "太短"
                                }
                                """))
                .andExpect(status().isBadRequest());

        sendAppealCode("appeal-nobody@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "appeal-nobody@example.com",
                                  "code": "123456",
                                  "reason": "不存在的账号提交申诉应该直接被拒绝。"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("账号不存在"));

        sendAppealCode("appeal-active@example.com");
        mockMvc.perform(post("/api/c/v1/auth/ban-appeals/query")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"appeal-active@example.com","code":"123456"}
                                """))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("该账号暂无申诉记录"));
    }

    private void banUser(String adminToken, long userId, String reason) throws Exception {
        mockMvc.perform(put("/api/admin/v1/users/{userId}/status", userId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"action":"ban","reason":"%s"}
                                """.formatted(reason)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));
    }

    private long pendingTaskId(long appealId) {
        Long taskId = jdbc.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type = 8 AND biz_id = ? AND status = 0",
                Long.class,
                appealId
        );
        assertThat(taskId).isNotNull();
        return taskId;
    }

    private void sendAppealCode(String account) throws Exception {
        sendCodeRateLimitService.clearAll();
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "appeal",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "user-ban-appeal-test"
                                }
                                """.formatted(account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
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
        sendCodeRateLimitService.clearAll();
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "user-ban-appeal-test"
                                }
                                """.formatted(email)))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "%s",
                                  "nickname": "封禁申诉测试用户"
                                }
                                """.formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn();
        return new SessionFixture(
                readText(result, "/data/accessToken"),
                Long.parseLong(readText(result, "/data/user/id"))
        );
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
