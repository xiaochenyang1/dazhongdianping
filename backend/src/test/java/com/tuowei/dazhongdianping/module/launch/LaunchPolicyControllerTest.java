package com.tuowei.dazhongdianping.module.launch;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class LaunchPolicyControllerTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;

    @Test
    void publishesRegionSpecificCapabilitiesWithoutAuthentication() throws Exception {
        for (String region : new String[]{"EU", "CN"}) {
            mvc.perform(get("/api/c/v1/launch-config").header("X-Region", region))
                    .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                    .andExpect(jsonPath("$.data.region").value(region))
                    .andExpect(jsonPath("$.data.creatorRewards").value(region.equals("CN")))
                    .andExpect(jsonPath("$.data.seckill").value(region.equals("CN")))
                    .andExpect(jsonPath("$.data.groupBuy").value(region.equals("CN")));
        }
    }

    @Test
    void euDirectRequestsCannotClaimRewardsOrParticipateInDeferredCampaigns() throws Exception {
        String account = "launch-policy-" + UUID.randomUUID() + "@example.com";
        mvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("scene", "register", "type", "email",
                                "account", account, "deviceId", "launch-policy"))))
                .andExpect(status().isOk());
        var registered = mvc.perform(post("/api/c/v1/auth/register").header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of(
                                "type", "email", "account", account, "code", "123456", "password", "Passw0rd!"))))
                .andExpect(status().isOk()).andReturn();
        var user = json.readTree(registered.getResponse().getContentAsString()).path("data");
        String authorization = "Bearer " + user.path("accessToken").asText();
        long userId = user.at("/user/id").asLong();

        // A claim made before the launch switch was disabled must not award points either.
        jdbc.update("INSERT INTO creator_task_claim(task_id,user_id,region,status) VALUES(9102,?,'EU',1)", userId);
        jdbc.update("""
                INSERT INTO seckill_event(id,region,shop_id,merchant_id,title,seckill_price,currency,stock,
                    start_at,end_at,status,audit_status)
                VALUES(66001,'EU',20001,2001,'Launch test',1,'EUR',10,'2026-01-01','2030-01-01',1,2)
                """);
        jdbc.update("""
                INSERT INTO groupbuy_campaign(id,region,shop_id,merchant_id,title,group_price,currency,start_at,end_at,audit_status)
                VALUES(66002,'EU',20001,2001,'Launch test',1,'EUR','2026-01-01','2030-01-01',2)
                """);
        jdbc.update("""
                INSERT INTO groupbuy_team(id,campaign_id,region,leader_user_id,expire_at)
                VALUES(66003,66002,'EU',9001,'2030-01-01')
                """);

        for (String path : new String[]{"/creator/tasks", "/marketing/seckill", "/marketing/groupbuy"}) {
            mvc.perform(get("/api/c/v1" + path).header("X-Region", "EU").header("Authorization", authorization))
                    .andExpect(status().isForbidden());
        }
        for (String path : new String[]{"/creator/tasks/9102/claim", "/creator/tasks/9102/complete",
                "/marketing/seckill/66001/claim", "/marketing/groupbuy/66002/teams", "/marketing/groupbuy/teams/66003/join"}) {
            mvc.perform(post("/api/c/v1" + path).header("X-Region", "EU").header("Authorization", authorization))
                    .andExpect(status().isForbidden()).andExpect(jsonPath("$.message").value("该功能暂未在当前区域开放"));
        }

        assertThat(jdbc.queryForObject("SELECT points FROM app_user WHERE id=?", Integer.class, userId)).isZero();
        assertThat(jdbc.queryForObject("SELECT status FROM creator_task_claim WHERE user_id=?", Integer.class, userId)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM growth_points_log WHERE user_id=? AND action='creator_task'", Integer.class, userId)).isZero();
        assertThat(jdbc.queryForObject("SELECT sold FROM seckill_event WHERE id=66001", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM seckill_claim WHERE user_id=?", Integer.class, userId)).isZero();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM groupbuy_team WHERE campaign_id=66002", Integer.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT member_count FROM groupbuy_team WHERE id=66003", Integer.class)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM groupbuy_member WHERE user_id=?", Integer.class, userId)).isZero();

        mvc.perform(get("/api/c/v1/marketing/coupons/center").header("X-Region", "EU").header("Authorization", authorization))
                .andExpect(status().isOk());
        mvc.perform(get("/api/c/v1/deals/41001").header("X-Region", "EU"))
                .andExpect(status().isOk());
    }
}
