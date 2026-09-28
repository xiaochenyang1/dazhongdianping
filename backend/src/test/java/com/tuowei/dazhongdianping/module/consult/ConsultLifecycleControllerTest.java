package com.tuowei.dazhongdianping.module.consult;

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
class ConsultLifecycleControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void userAndMerchantExchangeMessages() throws Exception {
        String user = registerUser();

        // 1) 用户对门店 10001 发起会话（幂等：第二次返回同一会话）。
        MvcResult started = mockMvc.perform(post("/api/c/v1/consult/sessions")
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001}"))
                .andExpect(status().isOk())
                .andReturn();
        long sessionId = objectMapper.readTree(started.getResponse().getContentAsString()).at("/data/id").asLong();

        MvcResult again = mockMvc.perform(post("/api/c/v1/consult/sessions")
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001}"))
                .andExpect(status().isOk()).andReturn();
        long sessionIdAgain = objectMapper.readTree(again.getResponse().getContentAsString()).at("/data/id").asLong();
        org.assertj.core.api.Assertions.assertThat(sessionIdAgain).isEqualTo(sessionId);

        // 2) 用户发消息。
        mockMvc.perform(post("/api/c/v1/consult/sessions/{id}/messages", sessionId)
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"请问还有位置吗？\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.senderType").value(1));

        // 3) 商家看到会话且有未读，读取后未读清零。
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        mockMvc.perform(get("/api/b/v1/consult/sessions")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + sessionId + ")].unread").value(org.hamcrest.Matchers.hasItem(1)));

        mockMvc.perform(get("/api/b/v1/consult/sessions/{id}/messages", sessionId)
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages.length()").value(1))
                .andExpect(jsonPath("$.data.session.unread").value(0));

        // 4) 商家回复。
        mockMvc.perform(post("/api/b/v1/consult/sessions/{id}/messages", sessionId)
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"有的，直接过来即可。\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.senderType").value(2));

        // 5) 用户侧未读 +1，读取消息后清零，能看到两条消息。
        mockMvc.perform(get("/api/c/v1/consult/sessions")
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + sessionId + ")].unread").value(org.hamcrest.Matchers.hasItem(1)));

        mockMvc.perform(get("/api/c/v1/consult/sessions/{id}/messages", sessionId)
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages.length()").value(2))
                .andExpect(jsonPath("$.data.session.unread").value(0));
    }

    @Test
    void startRejectsUnknownShop() throws Exception {
        String user = registerUser();
        mockMvc.perform(post("/api/c/v1/consult/sessions")
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":99999999}"))
                .andExpect(status().isNotFound());
    }

    private String registerUser() throws Exception {
        String account = "consult-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"consult-test\"}"))
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
