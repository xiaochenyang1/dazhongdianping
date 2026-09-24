package com.tuowei.dazhongdianping.module.riskcontrol;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
class RiskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void adminCanListRulesSeededPerRegion() throws Exception {
        String token = adminToken();
        mockMvc.perform(get("/api/admin/v1/risk/rules")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].ruleCode").exists());
    }

    @Test
    void adminCanUpdateRule() throws Exception {
        String token = adminToken();
        Long ruleId = jdbcTemplate.queryForObject(
                "SELECT id FROM risk_rule WHERE region='CN' AND rule_code='review_freq'", Long.class);

        mockMvc.perform(put("/api/admin/v1/risk/rules/" + ruleId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":3,\"threshold\":9,\"windowSeconds\":1800,\"riskScore\":55,\"enabled\":true,\"remark\":\"tuned\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.risk_rule_saved"))
                .andExpect(jsonPath("$.data.threshold").value(9))
                .andExpect(jsonPath("$.data.action").value(3));
    }

    @Test
    void ruleUpdateRejectsInvalidAction() throws Exception {
        String token = adminToken();
        Long ruleId = jdbcTemplate.queryForObject(
                "SELECT id FROM risk_rule WHERE region='CN' AND rule_code='review_freq'", Long.class);
        mockMvc.perform(put("/api/admin/v1/risk/rules/" + ruleId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":9,\"threshold\":9,\"windowSeconds\":1800,\"riskScore\":55,\"enabled\":true}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void eventsEndpointRequiresPermission() throws Exception {
        // 无 token → 401
        mockMvc.perform(get("/api/admin/v1/risk/events").header("X-Region", "CN"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void duplicateReviewIsBlockedAndRecordsEvent() throws Exception {
        String account = "risk-dup@example.com";
        String token = registerUser(account, "刷单用户");
        Long shopId = jdbcTemplate.queryForObject(
                "SELECT id FROM shop WHERE region='CN' AND status=1 AND is_deleted=FALSE ORDER BY id LIMIT 1",
                Long.class);
        String body = reviewBody(shopId, "这家餐厅环境很好菜品也不错服务态度佳强烈推荐大家都来尝试一下");

        // 第一条正常通过
        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .header("X-Device-Id", "risk-dup-device")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk());

        // 第二条内容几乎相同 → 相似度规则拦截 403
        mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .header("X-Device-Id", "risk-dup-device")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.messageKey").value("riskcontrol.review_blocked"));

        // 风控事件已落库
        Integer events = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM risk_event WHERE region='CN' AND scene='review_create' AND decision=3",
                Integer.class);
        org.junit.jupiter.api.Assertions.assertTrue(events != null && events >= 1);
    }

    private String reviewBody(Long shopId, String content) {
        return """
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
                """.formatted(shopId, content);
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String registerUser(String account, String nickname) throws Exception {
        String deviceId = "risk-" + account.replaceAll("[^a-zA-Z0-9]", "-");
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
        return objectMapper.readTree(registerResult.getResponse().getContentAsString()).at("/data/accessToken").asText();
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
