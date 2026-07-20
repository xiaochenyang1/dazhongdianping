package com.tuowei.dazhongdianping.module.auth.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.auth.service.SendCodeRateLimitService;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {
        "app.auth.send-code-rate-limit.device-window-max-requests=3",
        "app.auth.send-code-rate-limit.ip-window-max-requests=10"
})
class PublicAuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private SendCodeRateLimitService sendCodeRateLimitService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void resetRateLimitState() {
        sendCodeRateLimitService.clearAll();
    }

    @AfterEach
    void clearRateLimitState() {
        sendCodeRateLimitService.clearAll();
    }

    @Test
    void shouldSendMockCodeForRegister() throws Exception {
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "alice@example.com",
                                  "deviceId": "web-local-001"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.sent").value(true))
                .andExpect(jsonPath("$.data.expireSeconds").value(300))
                .andExpect(jsonPath("$.data.nextRetrySeconds").value(60))
                .andExpect(jsonPath("$.data.mockCode").value("123456"));
    }

    @Test
    void shouldRegisterAndFetchCurrentUserProfile() throws Exception {
        sendCode("register", "email", "alice@example.com");

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "alice@example.com",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "阿辽沙",
                                  "preferredRegion": "EU"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.refreshToken").isNotEmpty())
                .andExpect(jsonPath("$.data.user.nickname").value("阿辽沙"))
                .andExpect(jsonPath("$.data.user.preferredRegion").value("EU"))
                .andReturn();

        String accessToken = readText(registerResult, "/data/accessToken");

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.nickname").value("阿辽沙"))
                .andExpect(jsonPath("$.data.preferredRegion").value("EU"))
                .andExpect(jsonPath("$.data.email").value("alice@example.com"));
    }

    @Test
    void shouldUpdateCurrentUserProfile() throws Exception {
        sendCode("register", "email", "profile@example.com");

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "profile@example.com",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "旧昵称"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();

        String accessToken = readText(registerResult, "/data/accessToken");

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put("/api/c/v1/user/profile")
                        .header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "nickname": "新昵称",
                                  "avatar": "https://placehold.co/200x200/f97316/ffffff?text=USER",
                                  "gender": 1,
                                  "signature": "本地开发先把资料页闭环跑通。"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.nickname").value("新昵称"))
                .andExpect(jsonPath("$.data.avatar").value("https://placehold.co/200x200/f97316/ffffff?text=USER"));

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.nickname").value("新昵称"))
                .andExpect(jsonPath("$.data.avatar").value("https://placehold.co/200x200/f97316/ffffff?text=USER"));
    }

    @Test
    void shouldLoginWithPasswordRefreshAndLogoutSession() throws Exception {
        sendCode("register", "email", "bob@example.com");
        mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "bob@example.com",
                                  "code": "123456",
                                  "password": "Passw0rd!"
                                }
                                """))
                .andExpect(status().isOk());

        MvcResult loginResult = mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "bob@example.com",
                                  "password": "Passw0rd!"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.refreshToken").isNotEmpty())
                .andReturn();

        String loginAccessToken = readText(loginResult, "/data/accessToken");
        String loginRefreshToken = readText(loginResult, "/data/refreshToken");

        MvcResult refreshResult = mockMvc.perform(post("/api/c/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "refreshToken": "%s"
                                }
                                """.formatted(loginRefreshToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.refreshToken").isNotEmpty())
                .andReturn();

        String refreshedAccessToken = readText(refreshResult, "/data/accessToken");

        mockMvc.perform(post("/api/c/v1/auth/logout")
                        .header("Authorization", bearer(refreshedAccessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(loginAccessToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(refreshedAccessToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldLoginWithCodeAndAutoCreateUser() throws Exception {
        sendCode("login", "phone", "+447700900123");

        MvcResult loginResult = mockMvc.perform(post("/api/c/v1/auth/login/code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "phone",
                                  "account": "+447700900123",
                                  "code": "123456",
                                  "preferredRegion": "EU"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.refreshToken").isNotEmpty())
                .andExpect(jsonPath("$.data.user.preferredRegion").value("EU"))
                .andReturn();

        String accessToken = readText(loginResult, "/data/accessToken");

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.phone").value("+447700900123"))
                .andExpect(jsonPath("$.data.preferredRegion").value("EU"));
    }

    @Test
    void shouldResetPasswordAndAllowLoginWithNewPassword() throws Exception {
        sendCode("register", "email", "reset@example.com");
        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "reset@example.com",
                                  "code": "123456",
                                  "password": "OldPass1!"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        String registerAccessToken = readText(registerResult, "/data/accessToken");
        String registerRefreshToken = readText(registerResult, "/data/refreshToken");

        MvcResult loginResult = mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "reset@example.com",
                                  "password": "OldPass1!"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        String loginAccessToken = readText(loginResult, "/data/accessToken");
        String loginRefreshToken = readText(loginResult, "/data/refreshToken");

        sendCode("reset", "email", "reset@example.com");

        mockMvc.perform(post("/api/c/v1/auth/password/reset")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "reset@example.com",
                                  "code": "123456",
                                  "newPassword": "NewPass2!"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        assertSessionRevoked(registerAccessToken, registerRefreshToken);
        assertSessionRevoked(loginAccessToken, loginRefreshToken);

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "reset@example.com",
                                  "password": "OldPass1!"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "reset@example.com",
                                  "password": "NewPass2!"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty());
    }

    @Test
    void shouldRateLimitSendCodeByAccountAndReturnRetryAfterHeader() throws Exception {
        sendCodeWith("register", "email", "limit-account@example.com", "device-limit-account", "203.0.113.10")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        sendCodeWith("register", "email", "limit-account@example.com", "device-limit-account", "203.0.113.10")
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value(429))
                .andExpect(jsonPath("$.message").value("验证码发送太频繁，请稍后再试"))
                .andExpect(jsonPath("$.messageKey").value("common.too_many_requests"))
                .andExpect(result -> {
                    String retryAfter = result.getResponse().getHeader("Retry-After");
                    if (retryAfter == null || Integer.parseInt(retryAfter) < 1) {
                        throw new AssertionError("Retry-After 头缺失或不合法");
                    }
                });
    }

    @Test
    void shouldRateLimitSendCodeByDeviceId() throws Exception {
        for (int index = 1; index <= 3; index++) {
            sendCodeWith(
                    "register",
                    "email",
                    "limit-device-%d@example.com".formatted(index),
                    "device-limit-shared",
                    "203.0.113.20"
            )
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.code").value(0));
        }

        sendCodeWith("register", "email", "limit-device-4@example.com", "device-limit-shared", "203.0.113.20")
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value(429))
                .andExpect(result -> {
                    String retryAfter = result.getResponse().getHeader("Retry-After");
                    if (retryAfter == null || Integer.parseInt(retryAfter) < 1) {
                        throw new AssertionError("Retry-After 头缺失或不合法");
                    }
                });
    }

    @Test
    void shouldRateLimitSendCodeByRequestIp() throws Exception {
        String requestIp = "203.0.113.30";
        for (int index = 1; index <= 10; index++) {
            sendCodeWith(
                    "register",
                    "email",
                    "limit-ip-%d@example.com".formatted(index),
                    "device-limit-ip-%d".formatted(index),
                    requestIp
            )
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.code").value(0));
        }

        sendCodeWith("register", "email", "limit-ip-11@example.com", "device-limit-ip-11", requestIp)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.code").value(429))
                .andExpect(result -> {
                    String retryAfter = result.getResponse().getHeader("Retry-After");
                    if (retryAfter == null || Integer.parseInt(retryAfter) < 1) {
                        throw new AssertionError("Retry-After 头缺失或不合法");
                    }
                });
    }

    @Test
    void shouldUpdateCurrentUserPasswordAndUseNewPasswordToLogin() throws Exception {
        sendCode("register", "email", "password@example.com");
        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "password@example.com",
                                  "code": "123456",
                                  "password": "OldPass1!"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        String accessToken = readText(registerResult, "/data/accessToken");
        String refreshToken = readText(registerResult, "/data/refreshToken");

        MvcResult secondLoginResult = mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "password@example.com",
                                  "password": "OldPass1!"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        String secondAccessToken = readText(secondLoginResult, "/data/accessToken");
        String secondRefreshToken = readText(secondLoginResult, "/data/refreshToken");

        mockMvc.perform(put("/api/c/v1/user/password")
                        .header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "oldPassword": "OldPass1!",
                                  "newPassword": "NewPass2!"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        assertSessionRevoked(accessToken, refreshToken);
        assertSessionRevoked(secondAccessToken, secondRefreshToken);

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "password@example.com",
                                  "password": "OldPass1!"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "password@example.com",
                                  "password": "NewPass2!"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty());
    }

    @Test
    void shouldBindPhoneForCurrentUserAndAllowPasswordLoginWithPhone() throws Exception {
        sendCode("register", "email", "bind@example.com");
        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "bind@example.com",
                                  "code": "123456",
                                  "password": "BindPass1!"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        String accessToken = readText(registerResult, "/data/accessToken");
        sendCode("bind", "phone", "+447700900321");

        mockMvc.perform(post("/api/c/v1/user/bind")
                        .header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "phone",
                                  "account": "+447700900321",
                                  "code": "123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.phone").value("+447700900321"));

        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.phone").value("+447700900321"));

        mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "+447700900321",
                                  "password": "BindPass1!"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty());
    }

    @Test
    void shouldExposePublicUserProfileWithoutSensitiveFields() throws Exception {
        sendCode("register", "email", "public@example.com");
        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "public@example.com",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "公开用户"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        String userId = readText(registerResult, "/data/user/id");

        mockMvc.perform(get("/api/c/v1/user/{userId}", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").value(Long.parseLong(userId)))
                .andExpect(jsonPath("$.data.nickname").value("公开用户"))
                .andExpect(jsonPath("$.data.signature").value(""))
                .andExpect(jsonPath("$.data.reviewCount").value(0))
                .andExpect(jsonPath("$.data.email").doesNotExist())
                .andExpect(jsonPath("$.data.phone").doesNotExist());
    }

    @Test
    void shouldCountPublicReviewsWithinCurrentRegionOnPublicProfile() throws Exception {
        sendCode("register", "email", "public-region@example.com");
        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "public-region@example.com",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "跨区公开用户",
                                  "preferredRegion": "EU"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        long userId = Long.parseLong(readText(registerResult, "/data/user/id"));
        insertPublicReview(91001L, userId, 10001L, "CN", "中国区第一条公开点评");
        insertPublicReview(91002L, userId, 10002L, "CN", "中国区第二条公开点评");
        insertPublicReview(91003L, userId, 20001L, "EU", "欧洲区公开点评");

        mockMvc.perform(get("/api/c/v1/user/{userId}", userId)
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").value(userId))
                .andExpect(jsonPath("$.data.preferredRegion").value("EU"))
                .andExpect(jsonPath("$.data.reviewCount").value(2));

        mockMvc.perform(get("/api/c/v1/user/{userId}", userId)
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.id").value(userId))
                .andExpect(jsonPath("$.data.preferredRegion").value("EU"))
                .andExpect(jsonPath("$.data.reviewCount").value(1));
    }

    @Test
    void shouldListGrowthRecordsAfterCreatingReview() throws Exception {
        jdbcTemplate.update("UPDATE growth_rule SET enabled = FALSE WHERE action = 'review_image'");
        sendCode("register", "email", "growth-records@example.com");
        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "growth-records@example.com",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "积分记录用户"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();

        String accessToken = readText(registerResult, "/data/accessToken");

        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001L, "为了查积分流水，先正儿八经写条点评。", 5, 5, 4, 5, 99.00)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        mockMvc.perform(get("/api/c/v1/user/growth/records")
                        .header("Authorization", bearer(accessToken))
                        .param("page", "1")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.hasMore").value(false))
                .andExpect(jsonPath("$.data.list[0].type").value(2))
                .andExpect(jsonPath("$.data.list[0].typeText").value("积分"))
                .andExpect(jsonPath("$.data.list[0].action").value("review_create"))
                .andExpect(jsonPath("$.data.list[0].actionText").value("发布点评"))
                .andExpect(jsonPath("$.data.list[0].changeAmount").value(5))
                .andExpect(jsonPath("$.data.list[0].balanceAfter").value(5))
                .andExpect(jsonPath("$.data.list[0].remark").value("发布点评奖励"))
                .andExpect(jsonPath("$.data.list[0].createdAt").isNotEmpty())
                .andExpect(jsonPath("$.data.list[1].type").value(1))
                .andExpect(jsonPath("$.data.list[1].typeText").value("成长值"))
                .andExpect(jsonPath("$.data.list[1].action").value("review_create"))
                .andExpect(jsonPath("$.data.list[1].actionText").value("发布点评"))
                .andExpect(jsonPath("$.data.list[1].changeAmount").value(10))
                .andExpect(jsonPath("$.data.list[1].balanceAfter").value(10))
                .andExpect(jsonPath("$.data.list[1].remark").value("发布点评奖励"))
                .andExpect(jsonPath("$.data.list[1].createdAt").isNotEmpty());
    }

    @Test
    void shouldApplyConfiguredGrowthRuleLevelAndDailyLimit() throws Exception {
        jdbcTemplate.update("UPDATE growth_rule SET growth_value = 25, points = 9, daily_limit = 1 WHERE action = 'review_create'");
        jdbcTemplate.update("UPDATE growth_rule SET enabled = FALSE WHERE action = 'review_image'");
        sendCode("register", "email", "growth-config@example.com");
        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"growth-config@example.com","code":"123456","password":"Passw0rd!","nickname":"配置奖励用户"}
                                """))
                .andExpect(status().isOk()).andReturn();
        String accessToken = readText(registerResult, "/data/accessToken");

        mockMvc.perform(post("/api/c/v1/reviews").header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10001L, "第一条点评应该按数据库规则奖励。", 5, 5, 5, 5, 120.00)))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/c/v1/reviews").header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reviewPayload(10002L, "第二条点评达到每日上限，不应重复奖励。", 4, 4, 4, 4, 50.00)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/user/me").header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.growthValue").value(25))
                .andExpect(jsonPath("$.data.points").value(9))
                .andExpect(jsonPath("$.data.level").value(2));
        mockMvc.perform(get("/api/c/v1/user/growth/records").header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].changeAmount").value(9))
                .andExpect(jsonPath("$.data.list[1].changeAmount").value(25));
    }

    private void sendCode(String scene, String type, String account) throws Exception {
        sendCodeWith(scene, type, account, "web-local-001", "127.0.0.1")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));
    }

    private org.springframework.test.web.servlet.ResultActions sendCodeWith(String scene,
                                                                            String type,
                                                                            String account,
                                                                            String deviceId,
                                                                            String requestIp) throws Exception {
        return mockMvc.perform(post("/api/c/v1/auth/send-code")
                .with(request -> {
                    request.setRemoteAddr(requestIp);
                    return request;
                })
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {
                          "scene": "%s",
                          "type": "%s",
                          "account": "%s",
                          "deviceId": "%s"
                        }
                                """.formatted(scene, type, account, deviceId)));
    }

    private void insertPublicReview(long reviewId,
                                    long userId,
                                    long shopId,
                                    String region,
                                    String content) {
        jdbcTemplate.update("""
                        INSERT INTO review(
                            id,
                            user_id,
                            shop_id,
                            region,
                            user_name,
                            content,
                            score_overall,
                            currency,
                            audit_status,
                            status,
                            created_at,
                            updated_at,
                            is_deleted
                        )
                        VALUES (?, ?, ?, ?, ?, ?, 4.5, ?, 1, 1, ?, ?, FALSE)
                        """,
                reviewId,
                userId,
                shopId,
                region,
                "公开用户-" + userId,
                content,
                "EU".equals(region) ? "EUR" : "CNY",
                Timestamp.valueOf(LocalDateTime.now().minusMinutes(5)),
                Timestamp.valueOf(LocalDateTime.now()));
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }

    private String reviewPayload(long shopId,
                                 String content,
                                 int scoreOverall,
                                 int scoreTaste,
                                 int scoreEnv,
                                 int scoreService,
                                 double cost) {
        return """
                {
                  "shopId": %d,
                  "content": "%s",
                  "scoreOverall": %d,
                  "scoreTaste": %d,
                  "scoreEnv": %d,
                  "scoreService": %d,
                  "cost": %.2f,
                  "currency": "CNY",
                  "tags": ["真有提升", "能查流水"],
                  "images": [
                    "https://placehold.co/800x520/f97316/ffffff?text=Growth+1"
                  ]
                }
                """.formatted(shopId, content, scoreOverall, scoreTaste, scoreEnv, scoreService, cost);
    }

    private void assertSessionRevoked(String accessToken, String refreshToken) throws Exception {
        mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        mockMvc.perform(post("/api/c/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "refreshToken": "%s"
                                }
                                """.formatted(refreshToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }
}
