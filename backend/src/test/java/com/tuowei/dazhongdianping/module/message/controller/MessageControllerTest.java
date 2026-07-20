package com.tuowei.dazhongdianping.module.message.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
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
class MessageControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldCreateOneConversationSendPageAndMarkMessagesRead() throws Exception {
        UserAccess sender = registerUser("私信发送者");
        UserAccess receiver = registerUser("私信接收者");

        MvcResult first = send(sender, receiver.id(), "第一条消息")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content").value("第一条消息"))
                .andExpect(jsonPath("$.data.fromUserId").value(sender.id()))
                .andExpect(jsonPath("$.data.toUserId").value(receiver.id()))
                .andExpect(jsonPath("$.data.read").value(false))
                .andReturn();
        long conversationId = readLong(first, "/data/conversationId");

        send(sender, receiver.id(), "第二条消息")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.conversationId").value(conversationId));
        send(receiver, sender.id(), "回复消息")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.conversationId").value(conversationId));

        mockMvc.perform(get("/api/c/v1/messages/conversations")
                        .header("Authorization", bearer(receiver.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(conversationId))
                .andExpect(jsonPath("$.data.list[0].peerUserId").value(sender.id()))
                .andExpect(jsonPath("$.data.list[0].lastMessagePreview").value("回复消息"))
                .andExpect(jsonPath("$.data.list[0].unreadCount").value(2));

        mockMvc.perform(get("/api/c/v1/messages/conversations/{id}", conversationId)
                        .param("page", "1").param("pageSize", "2")
                        .header("Authorization", bearer(receiver.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(3))
                .andExpect(jsonPath("$.data.list.length()").value(2))
                .andExpect(jsonPath("$.data.list[0].content").value("回复消息"))
                .andExpect(jsonPath("$.data.list[1].content").value("第二条消息"))
                .andExpect(jsonPath("$.data.hasMore").value(true));

        mockMvc.perform(post("/api/c/v1/messages/conversations/{id}/read", conversationId)
                        .header("Authorization", bearer(receiver.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.conversationId").value(conversationId))
                .andExpect(jsonPath("$.data.markedReadCount").value(2));

        mockMvc.perform(get("/api/c/v1/messages/conversations")
                        .header("Authorization", bearer(receiver.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].unreadCount").value(0));
    }

    @Test
    void shouldRejectInvalidRecipientsAndBlockSendingInEitherDirection() throws Exception {
        UserAccess first = registerUser("拉黑用户甲");
        UserAccess second = registerUser("拉黑用户乙");
        UserAccess deleted = registerUser("已注销用户");

        send(first, first.id(), "不能发给自己").andExpect(status().isBadRequest());
        send(first, 99999999L, "目标不存在").andExpect(status().isNotFound());
        jdbcTemplate.update("UPDATE app_user SET status=0,is_deleted=TRUE WHERE id=?", deleted.id());
        send(first, deleted.id(), "目标已注销").andExpect(status().isNotFound());

        mockMvc.perform(put("/api/c/v1/messages/blocks/{userId}", second.id())
                        .header("Authorization", bearer(first.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.userId").value(second.id()))
                .andExpect(jsonPath("$.data.blocked").value(true));
        mockMvc.perform(put("/api/c/v1/messages/blocks/{userId}", second.id())
                        .header("Authorization", bearer(first.token())))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/messages/blocks")
                        .header("Authorization", bearer(first.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(second.id()));

        send(first, second.id(), "拉黑后不能发送").andExpect(status().isConflict());
        send(second, first.id(), "被拉黑方也不能发送").andExpect(status().isConflict());

        mockMvc.perform(delete("/api/c/v1/messages/blocks/{userId}", second.id())
                        .header("Authorization", bearer(first.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.blocked").value(false));
        mockMvc.perform(delete("/api/c/v1/messages/blocks/{userId}", second.id())
                        .header("Authorization", bearer(first.token())))
                .andExpect(status().isOk());
        send(second, first.id(), "解除后恢复发送").andExpect(status().isOk());
    }

    @Test
    void shouldReportMessageAndConversationOnlyOnce() throws Exception {
        UserAccess sender = registerUser("举报发送者");
        UserAccess receiver = registerUser("举报接收者");
        MvcResult sent = send(sender, receiver.id(), "违规消息").andExpect(status().isOk()).andReturn();
        long messageId = readLong(sent, "/data/id");
        long conversationId = readLong(sent, "/data/conversationId");

        report(receiver, 1, messageId, "骚扰内容")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.targetType").value(1))
                .andExpect(jsonPath("$.data.targetId").value(messageId));
        report(receiver, 1, messageId, "重复举报").andExpect(status().isConflict());

        report(receiver, 2, conversationId, "举报会话")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.targetType").value(2))
                .andExpect(jsonPath("$.data.targetId").value(conversationId));
        report(receiver, 2, conversationId, "重复举报").andExpect(status().isConflict());
    }

    private org.springframework.test.web.servlet.ResultActions send(UserAccess sender, long toUserId, String content)
            throws Exception {
        return mockMvc.perform(post("/api/c/v1/messages/send")
                .header("Authorization", bearer(sender.token()))
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"toUserId":%d,"content":"%s"}
                        """.formatted(toUserId, content)));
    }

    private org.springframework.test.web.servlet.ResultActions report(
            UserAccess reporter, int targetType, long targetId, String reason) throws Exception {
        return mockMvc.perform(post("/api/c/v1/messages/report")
                .header("Authorization", bearer(reporter.token()))
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"targetType":%d,"targetId":%d,"reason":"%s"}
                        """.formatted(targetType, targetId, reason)));
    }

    private UserAccess registerUser(String nickname) throws Exception {
        String account = "message-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> { request.setRemoteAddr("10.88.12.9"); return request; })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scene":"register","type":"email","account":"%s","deviceId":"message-test"}
                                """.formatted(account)))
                .andExpect(status().isOk());
        MvcResult register = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"%s","code":"123456","password":"Passw0rd!","nickname":"%s","preferredRegion":"EU"}
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andReturn();
        String token = readText(register, "/data/accessToken");
        MvcResult me = mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(token)).header("X-Region", "EU"))
                .andExpect(status().isOk()).andReturn();
        return new UserAccess(readLong(me, "/data/id"), token);
    }

    private String bearer(String token) { return "Bearer " + token; }
    private String readText(MvcResult result, String pointer) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at(pointer).asText();
    }
    private long readLong(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asLong();
    }
    private record UserAccess(long id, String token) {}
}
