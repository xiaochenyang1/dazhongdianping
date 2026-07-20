package com.tuowei.dazhongdianping.module.auth.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.auth.service.SendCodeRateLimitService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class UserGovernanceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private SendCodeRateLimitService sendCodeRateLimitService;

    @BeforeEach
    void resetState() {
        sendCodeRateLimitService.clearAll();
    }

    @Test
    void shouldRecordPolicyAcceptanceAndManageCurrentUserDevices() throws Exception {
        String accessToken = registerUser("governance@example.com", "GovernancePass1!");

        mockMvc.perform(post("/api/c/v1/privacy/policies/accept")
                        .header("Authorization", bearer(accessToken))
                        .header("Idempotency-Key", "policy-accept-001")
                        .header("User-Agent", "Flutter/1.0")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "policyType": 1,
                                  "version": "2026.07",
                                  "locale": "zh-CN",
                                  "source": 3
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.policyType").value(1))
                .andExpect(jsonPath("$.data.version").value("2026.07"))
                .andExpect(jsonPath("$.data.locale").value("zh-CN"))
                .andExpect(jsonPath("$.data.source").value(3))
                .andExpect(jsonPath("$.data.userAgent").value("Flutter/1.0"));

        mockMvc.perform(get("/api/c/v1/privacy/policies")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].policyType").value(1))
                .andExpect(jsonPath("$.data[0].version").value("2026.07"));

        MvcResult registerDeviceResult = mockMvc.perform(post("/api/c/v1/devices/register")
                        .header("Authorization", bearer(accessToken))
                        .header("Idempotency-Key", "device-register-001")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "deviceUid": "android-governance-001",
                                  "platform": 2,
                                  "pushChannel": 0,
                                  "pushToken": "",
                                  "appVersion": "1.0.0"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.deviceUid").value("android-governance-001"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andReturn();

        long deviceId = readLong(registerDeviceResult, "/data/id");

        mockMvc.perform(post("/api/c/v1/devices/register")
                        .header("Authorization", bearer(accessToken))
                        .header("Idempotency-Key", "device-register-002")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "deviceUid": "android-governance-001",
                                  "platform": 2,
                                  "pushChannel": 1,
                                  "pushToken": "fcm-token-v1",
                                  "appVersion": "1.0.1"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(deviceId))
                .andExpect(jsonPath("$.data.pushChannel").value(1))
                .andExpect(jsonPath("$.data.appVersion").value("1.0.1"));

        mockMvc.perform(put("/api/c/v1/devices/{deviceId}/push-token", deviceId)
                        .header("Authorization", bearer(accessToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "pushChannel": 1,
                                  "pushToken": "fcm-token-v2",
                                  "appVersion": "1.0.2"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pushTokenSet").value(true))
                .andExpect(jsonPath("$.data.appVersion").value("1.0.2"));

        mockMvc.perform(get("/api/c/v1/devices")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(deviceId));

        mockMvc.perform(delete("/api/c/v1/devices/{deviceId}", deviceId)
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(deviceId))
                .andExpect(jsonPath("$.data.status").value(3))
                .andExpect(jsonPath("$.data.pushTokenSet").value(false));
    }

    private String registerUser(String email, String password) throws Exception {
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "governance-test-device"
                                }
                                """.formatted(email)))
                .andExpect(status().isOk());

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "%s",
                                  "nickname": "治理测试用户"
                                }
                                """.formatted(email, password)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(registerResult.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
    }

    private long readLong(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asLong();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
