package com.tuowei.dazhongdianping.module.waitlist;

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
class WaitlistLifecycleControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void joinCallSeatFlow() throws Exception {
        String user = registerUser();

        // 取号。
        MvcResult joined = mockMvc.perform(post("/api/c/v1/shops/{shopId}/waitlist", 10001)
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"tableType\":1,\"partySize\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("waitlist.joined"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.aheadCount").value(0))
                .andReturn();
        long entryId = objectMapper.readTree(joined.getResponse().getContentAsString()).at("/data/id").asLong();

        // 重复取号被拒。
        mockMvc.perform(post("/api/c/v1/shops/{shopId}/waitlist", 10001)
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"tableType\":1,\"partySize\":2}"))
                .andExpect(status().isConflict());

        // 我的排队可见。
        mockMvc.perform(get("/api/c/v1/waitlist/mine")
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + entryId + ")]").exists());

        // 商家看到队列并叫号。
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        mockMvc.perform(get("/api/b/v1/waitlist?shopId=10001")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + entryId + ")]").exists());

        mockMvc.perform(post("/api/b/v1/waitlist/{id}/call", entryId)
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));

        // 入座后不再在进行中列表。
        mockMvc.perform(post("/api/b/v1/waitlist/{id}/seat", entryId)
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(3));

        mockMvc.perform(get("/api/c/v1/waitlist/mine")
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + entryId + ")]").doesNotExist());
    }

    @Test
    void userCanCancelWhileQueuing() throws Exception {
        String user = registerUser();
        MvcResult joined = mockMvc.perform(post("/api/c/v1/shops/{shopId}/waitlist", 10001)
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"tableType\":2,\"partySize\":4}"))
                .andExpect(status().isOk()).andReturn();
        long entryId = objectMapper.readTree(joined.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(post("/api/c/v1/waitlist/{id}/cancel", entryId)
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(5));
    }

    @Test
    void joinRejectsUnknownShop() throws Exception {
        String user = registerUser();
        mockMvc.perform(post("/api/c/v1/shops/{shopId}/waitlist", 99999999L)
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"tableType\":1,\"partySize\":2}"))
                .andExpect(status().isNotFound());
    }

    private String registerUser() throws Exception {
        String account = "waitlist-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"waitlist-test\"}"))
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

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
