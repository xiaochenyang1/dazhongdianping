package com.tuowei.dazhongdianping.module.ticket;

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
class TicketControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void userCreatesListsAndReplies() throws Exception {
        String user = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/tickets")
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"subject\":\"券码无法核销\",\"content\":\"到店后券码一直失败\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("ticket.created"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.requesterType").value(1))
                .andExpect(jsonPath("$.data.messages.length()").value(1))
                .andReturn();
        long ticketId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/c/v1/tickets")
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + ticketId + ")]").exists());

        mockMvc.perform(get("/api/c/v1/tickets/{id}", ticketId)
                        .header("Authorization", bearer(user)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages[0].content").value("到店后券码一直失败"))
                .andExpect(jsonPath("$.data.messages[0].senderType").value(1));

        mockMvc.perform(post("/api/c/v1/tickets/{id}/messages", ticketId)
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"补充一下是晚饭时段\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.messages.length()").value(2))
                .andExpect(jsonPath("$.data.messages[1].content").value("补充一下是晚饭时段"));

        String other = registerUser();
        mockMvc.perform(get("/api/c/v1/tickets/{id}", ticketId)
                        .header("Authorization", bearer(other)).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
    }

    @Test
    void merchantCreatesTicketForOwnShop() throws Exception {
        String merchant = loginMerchant();
        MvcResult created = mockMvc.perform(post("/api/b/v1/tickets")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"subject\":\"营业时间有误\",\"content\":\"请改成11点开门\",\"shopId\":10001}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("merchant.ticket_created"))
                .andExpect(jsonPath("$.data.requesterType").value(2))
                .andExpect(jsonPath("$.data.requesterId").value(1001))
                .andExpect(jsonPath("$.data.shopId").value(10001))
                .andExpect(jsonPath("$.data.status").value(1))
                .andReturn();
        long ticketId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/b/v1/tickets")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + ticketId + ")]").exists());

        mockMvc.perform(post("/api/b/v1/tickets")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"subject\":\"不是我的店\",\"content\":\"试试别人的门店\",\"shopId\":10002}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void adminReplyMovesOpenTicketToProcessing() throws Exception {
        String user = registerUser();
        MvcResult created = mockMvc.perform(post("/api/c/v1/tickets")
                        .header("Authorization", bearer(user)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"subject\":\"订单金额不对\",\"content\":\"实付和页面不一致\"}"))
                .andExpect(status().isOk())
                .andReturn();
        long ticketId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        String admin = adminToken();
        mockMvc.perform(post("/api/admin/v1/tickets/{id}/reply", ticketId)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"content\":\"已受理，正在核对账单\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.messages[?(@.senderType==3)].content")
                        .value(org.hamcrest.Matchers.hasItem("已受理，正在核对账单")));

        mockMvc.perform(get("/api/admin/v1/tickets/{id}", ticketId)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));

        mockMvc.perform(post("/api/admin/v1/tickets/{id}/status", ticketId)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.ticket_updated"))
                .andExpect(jsonPath("$.data.status").value(3));
    }

    private String registerUser() throws Exception {
        String account = "ticket-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"ticket-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String loginMerchant() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"merchant_cn_hotpot@example.com\",\"password\":\"merchant123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
