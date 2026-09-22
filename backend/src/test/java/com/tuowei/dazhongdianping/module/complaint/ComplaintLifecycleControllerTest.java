package com.tuowei.dazhongdianping.module.complaint;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
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
class ComplaintLifecycleControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void fullLifecycleUserMerchantAdmin() throws Exception {
        String userToken = registerUser();

        // 1) 用户对门店 10001（商户 1001）发起投诉。
        MvcResult created = mockMvc.perform(post("/api/c/v1/complaints")
                        .header("Authorization", bearer(userToken)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"type\":1,\"title\":\"分量不符\",\"content\":\"套餐份量比展示少。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("complaint.created"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.logs.length()").value(1))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        // 用户能在我的投诉里看到。
        mockMvc.perform(get("/api/c/v1/complaints")
                        .header("Authorization", bearer(userToken)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)));

        // 2) 商户 1001 申辩，状态转为处理中。
        String merchantToken = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        mockMvc.perform(get("/api/b/v1/complaints")
                        .header("Authorization", bearer(merchantToken)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + id + ")]").exists());

        mockMvc.perform(post("/api/b/v1/complaints/{id}/reply", id)
                        .header("Authorization", bearer(merchantToken)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reply\":\"份量按标准配置，欢迎复核。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.merchantReply").value("份量按标准配置，欢迎复核。"));

        // 3) 平台仲裁解决，状态转为已解决。
        String adminToken = adminToken();
        mockMvc.perform(post("/api/admin/v1/complaints/{id}/dispose", id)
                        .header("Authorization", bearer(adminToken)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"resolved\":true,\"resolution\":\"已协调商家补偿，投诉成立。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.complaint_disposed"))
                .andExpect(jsonPath("$.data.status").value(3))
                .andExpect(jsonPath("$.data.resolution").value("已协调商家补偿，投诉成立。"));

        // 已处置的工单不可再次处置。
        mockMvc.perform(post("/api/admin/v1/complaints/{id}/dispose", id)
                        .header("Authorization", bearer(adminToken)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"resolved\":false,\"resolution\":\"重复处置\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("投诉当前状态不可处置"));
    }

    @Test
    void createRejectsUnknownShop() throws Exception {
        String userToken = registerUser();
        mockMvc.perform(post("/api/c/v1/complaints")
                        .header("Authorization", bearer(userToken)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":99999999,\"type\":1,\"title\":\"x\",\"content\":\"y\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("门店不存在"));
    }

    @Test
    void createRejectsInvalidPayload() throws Exception {
        String userToken = registerUser();
        mockMvc.perform(post("/api/c/v1/complaints")
                        .header("Authorization", bearer(userToken)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"type\":9,\"title\":\"\",\"content\":\"\"}"))
                .andExpect(status().isBadRequest());
    }

    private String registerUser() throws Exception {
        String account = "complaint-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"complaint-test\"}"))
                .andExpect(status().isOk());
        MvcResult r = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(r.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String loginMerchant(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"" + password + "\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
