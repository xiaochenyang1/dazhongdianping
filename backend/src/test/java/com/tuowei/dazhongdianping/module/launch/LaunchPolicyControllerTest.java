package com.tuowei.dazhongdianping.module.launch;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.region.Region;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
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
                    .andExpect(jsonPath("$.data.creatorRewards").value(false))
                    .andExpect(jsonPath("$.data.seckill").value(false))
                    .andExpect(jsonPath("$.data.groupBuy").value(false));
        }
    }

    @ParameterizedTest
    @ValueSource(strings = {"EU", "CN", " cn ", ""})
    void euUserCannotReenableRewardsOrCampaignsByChangingOrOmittingRegion(String regionHeader) throws Exception {
        String region = Region.fromHeader(regionHeader).name();
        long taskId = region.equals("EU") ? 9102 : 9101;
        long shopId = region.equals("EU") ? 20001 : 10001;
        long merchantId = region.equals("EU") ? 2001 : 1001;
        String account = "launch-policy-" + UUID.randomUUID() + "@example.com";
        mvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("scene", "register", "type", "email",
                                "account", account, "deviceId", "launch-policy"))))
                .andExpect(status().isOk());
        var registered = mvc.perform(post("/api/c/v1/auth/register").header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of(
                                "type", "email", "account", account, "code", "123456", "password", "Passw0rd!",
                                "preferredRegion", "EU"))))
                .andExpect(status().isOk()).andReturn();
        var user = json.readTree(registered.getResponse().getContentAsString()).path("data");
        String authorization = "Bearer " + user.path("accessToken").asText();
        long userId = user.at("/user/id").asLong();

        // A claim made before the launch switch was disabled must not award points either.
        jdbc.update("INSERT INTO creator_task_claim(task_id,user_id,region,status) VALUES(?,?,?,1)",
                taskId, userId, region);
        jdbc.update("""
                INSERT INTO seckill_event(id,region,shop_id,merchant_id,title,seckill_price,currency,stock,
                    start_at,end_at,status,audit_status)
                VALUES(66001,?,?,?,'Launch test',1,?,10,'2026-01-01','2030-01-01',1,2)
                """, region, shopId, merchantId, region.equals("EU") ? "EUR" : "CNY");
        jdbc.update("""
                INSERT INTO groupbuy_campaign(id,region,shop_id,merchant_id,title,group_price,currency,start_at,end_at,audit_status)
                VALUES(66002,?,?,?,'Launch test',1,?,'2026-01-01','2030-01-01',2)
                """, region, shopId, merchantId, region.equals("EU") ? "EUR" : "CNY");
        jdbc.update("""
                INSERT INTO groupbuy_team(id,campaign_id,region,leader_user_id,expire_at)
                VALUES(66003,66002,?,9001,'2030-01-01')
                """, region);

        for (String path : new String[]{"/creator/tasks", "/marketing/seckill", "/marketing/groupbuy"}) {
            mvc.perform(asUser(get("/api/c/v1" + path), authorization, regionHeader))
                    .andExpect(status().isForbidden());
        }
        for (String path : new String[]{"/creator/tasks/" + taskId + "/claim", "/creator/tasks/" + taskId + "/complete",
                "/marketing/seckill/66001/claim", "/marketing/groupbuy/66002/teams", "/marketing/groupbuy/teams/66003/join"}) {
            mvc.perform(asUser(post("/api/c/v1" + path), authorization, regionHeader))
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

        mvc.perform(get("/api/c/v1/user/me").header("X-Region", "EU").header("Authorization", authorization))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.preferredRegion").value("EU"))
                .andExpect(jsonPath("$.data.points").value(0));
        long productId = jdbc.queryForObject("SELECT MIN(id) FROM points_product WHERE region='EU'", Long.class);
        jdbc.update("UPDATE points_product SET points_price=20 WHERE id=?", productId);
        mvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId)
                        .header("X-Region", "EU").header("Authorization", authorization))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.message").value("积分不足"));

        mvc.perform(get("/api/c/v1/marketing/coupons/center").header("X-Region", "EU").header("Authorization", authorization))
                .andExpect(status().isOk());
        mvc.perform(get("/api/c/v1/deals/41001").header("X-Region", "EU"))
                .andExpect(status().isOk());
    }

    private MockHttpServletRequestBuilder asUser(MockHttpServletRequestBuilder request,
                                                 String authorization, String regionHeader) {
        if (!regionHeader.isEmpty()) request.header("X-Region", regionHeader);
        return request.header("Authorization", authorization);
    }
}
