package com.tuowei.dazhongdianping.module.auth.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
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
class UserCheckInControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRequireLoginForCheckIn() throws Exception {
        mockMvc.perform(post("/api/c/v1/user/check-in"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        mockMvc.perform(get("/api/c/v1/user/check-in/status"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldReportNotCheckedInBeforeFirstCheckIn() throws Exception {
        String token = registerUser("checkin-fresh@example.com", "未签到用户");

        mockMvc.perform(get("/api/c/v1/user/check-in/status").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.checkedInToday").value(false))
                .andExpect(jsonPath("$.data.streakDays").value(0))
                .andExpect(jsonPath("$.data.totalCount").value(0))
                // 奖励口径来自 growth_rule 的 check_in 规则种子（成长值 2 / 积分 1）。
                .andExpect(jsonPath("$.data.todayGrowthReward").value(2))
                .andExpect(jsonPath("$.data.todayPointsReward").value(1));
    }

    @Test
    void shouldCreditGrowthAndPointsOnFirstCheckIn() throws Exception {
        String account = "checkin-first@example.com";
        String token = registerUser(account, "首签用户");
        int pointsBefore = pointsOf(account);
        int growthBefore = growthOf(account);

        mockMvc.perform(post("/api/c/v1/user/check-in").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.checkedInToday").value(true))
                .andExpect(jsonPath("$.data.streakDays").value(1))
                .andExpect(jsonPath("$.data.totalCount").value(1));

        // 签到只入账一次：UserCheckInRow.points 仅是记录，真正加分走 rewardForCheckIn，
        // 一次奖励写两条流水（type=1 成长值、type=2 积分）。
        assertThat(pointsOf(account)).isEqualTo(pointsBefore + 1);
        assertThat(growthOf(account)).isEqualTo(growthBefore + 2);
        assertThat(pointsLogCount(account, "check_in", 1)).isEqualTo(1);
        assertThat(pointsLogCount(account, "check_in", 2)).isEqualTo(1);
    }

    @Test
    void shouldRejectDuplicateCheckInOnSameDay() throws Exception {
        String account = "checkin-dup@example.com";
        String token = registerUser(account, "重复签到用户");

        mockMvc.perform(post("/api/c/v1/user/check-in").header("Authorization", bearer(token)))
                .andExpect(status().isOk());
        int pointsAfterFirst = pointsOf(account);

        mockMvc.perform(post("/api/c/v1/user/check-in").header("Authorization", bearer(token)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("今天已经签过到了"));

        assertThat(pointsOf(account)).isEqualTo(pointsAfterFirst);
        assertThat(checkInCount(account)).isEqualTo(1);
    }

    @Test
    void shouldContinueStreakWhenYesterdayWasCheckedIn() throws Exception {
        String account = "checkin-streak@example.com";
        String token = registerUser(account, "连签用户");
        long userId = userIdOf(account);
        insertCheckIn(userId, LocalDate.now().minusDays(1), 4);

        mockMvc.perform(post("/api/c/v1/user/check-in").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.streakDays").value(5))
                .andExpect(jsonPath("$.data.totalCount").value(2));
    }

    @Test
    void shouldResetStreakAfterAGap() throws Exception {
        String account = "checkin-gap@example.com";
        String token = registerUser(account, "断签用户");
        long userId = userIdOf(account);
        insertCheckIn(userId, LocalDate.now().minusDays(3), 9);

        mockMvc.perform(post("/api/c/v1/user/check-in").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.streakDays").value(1))
                .andExpect(jsonPath("$.data.totalCount").value(2));
    }

    @Test
    void shouldDisplayZeroStreakWhenTheLatestCheckInIsStale() throws Exception {
        String account = "checkin-stale-status@example.com";
        String token = registerUser(account, "断签状态用户");
        insertCheckIn(userIdOf(account), LocalDate.now().minusDays(3), 9);

        mockMvc.perform(get("/api/c/v1/user/check-in/status").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.checkedInToday").value(false))
                .andExpect(jsonPath("$.data.streakDays").value(0))
                .andExpect(jsonPath("$.data.totalCount").value(1));
    }

    @Test
    void shouldKeepTheRecordedRewardAfterTheRuleChanges() throws Exception {
        String account = "checkin-recorded-reward@example.com";
        String token = registerUser(account, "奖励记录用户");

        mockMvc.perform(post("/api/c/v1/user/check-in").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.todayGrowthReward").value(2))
                .andExpect(jsonPath("$.data.todayPointsReward").value(1));

        jdbcTemplate.update(
                "UPDATE growth_rule SET growth_value = ?, points = ? WHERE action = 'check_in'",
                8, 4);

        mockMvc.perform(get("/api/c/v1/user/check-in/status").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.todayGrowthReward").value(2))
                .andExpect(jsonPath("$.data.todayPointsReward").value(1));
    }

    private void insertCheckIn(long userId, LocalDate date, int streakDays) {
        jdbcTemplate.update(
                "INSERT INTO user_check_in(user_id, check_in_date, streak_days, growth_value, points) "
                        + "VALUES(?,?,?,?,?)",
                userId, date, streakDays, 2, 1);
    }

    private long userIdOf(String account) {
        return jdbcTemplate.queryForObject(
                "SELECT id FROM app_user WHERE email = ?", Long.class, account);
    }

    private int pointsOf(String account) {
        return jdbcTemplate.queryForObject(
                "SELECT points FROM app_user WHERE email = ?", Integer.class, account);
    }

    private int growthOf(String account) {
        return jdbcTemplate.queryForObject(
                "SELECT growth_value FROM app_user WHERE email = ?", Integer.class, account);
    }

    private int checkInCount(String account) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM user_check_in WHERE user_id = ?", Integer.class, userIdOf(account));
    }

    private int pointsLogCount(String account, String action, int type) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM growth_points_log WHERE user_id = ? AND action = ? AND type = ?",
                Integer.class, userIdOf(account), action, type);
    }

    private String registerUser(String account, String nickname) throws Exception {
        String deviceId = "checkin-" + account.replaceAll("[^a-zA-Z0-9]", "-");
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> {
                            request.setRemoteAddr(testIpFor(account));
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "%s"
                                }
                                """.formatted(account, deviceId)))
                .andExpect(status().isOk());

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "%s",
                                  "preferredRegion": "CN"
                                }
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(registerResult.getResponse().getContentAsString())
                .at("/data/accessToken").asText();
    }

    private String testIpFor(String account) {
        int hash = account.hashCode();
        return "10.%d.%d.%d".formatted(
                Math.floorMod(hash, 223) + 1,
                Math.floorMod(hash / 223, 223) + 1,
                Math.floorMod(hash / (223 * 223), 223) + 1
        );
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }
}
