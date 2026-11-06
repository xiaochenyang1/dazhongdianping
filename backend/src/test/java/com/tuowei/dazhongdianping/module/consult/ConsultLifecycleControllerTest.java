package com.tuowei.dazhongdianping.module.consult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.jdbc.core.JdbcTemplate;
import static org.assertj.core.api.Assertions.assertThat;
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
    @Autowired private JdbcTemplate jdbc;
    @Autowired private org.mybatis.spring.SqlSessionTemplate sqlSession;
    @Autowired private org.springframework.transaction.PlatformTransactionManager transactionManager;
    @Autowired private com.tuowei.dazhongdianping.module.consult.mapper.ConsultMapper consultMapper;

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
                .andExpect(jsonPath("$.data.list[?(@.id==" + sessionId + ")].unread").value(org.hamcrest.Matchers.hasItem(1)));

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
                .andExpect(jsonPath("$.data.list[?(@.id==" + sessionId + ")].unread").value(org.hamcrest.Matchers.hasItem(1)));

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

    @Test
    void boundsLatestHistoryAndIncrementalReadsWithoutLosingNewReplies() throws Exception {
        String user = registerUser();
        long id = start(user);
        seedMessages(id, 205, 2);
        JsonNode initial = read("c", user, id, "");
        assertThat(initial.at("/messages").size()).isEqualTo(50);
        assertThat(initial.at("/messages/0/content").asText()).isEqualTo("message-155");
        assertThat(initial.at("/messages/49/content").asText()).isEqualTo("message-204");
        assertThat(initial.at("/hasMore").asBoolean()).isTrue();
        long cursor = initial.at("/nextAfterId").asLong();
        long before = initial.at("/nextBeforeId").asLong();
        seedMessages(id, 105, 2);
        jdbc.update("UPDATE consult_session SET user_unread=105 WHERE id=?", id);
        JsonNode history = read("c", user, id, "?beforeId=" + before + "&pageSize=100");
        assertThat(history.at("/messages").size()).isEqualTo(100);
        assertThat(history.at("/messages/0/content").asText()).isEqualTo("message-55");
        assertThat(history.at("/session/unread").asInt()).isEqualTo(105);
        JsonNode oldest = read("c", user, id, "?beforeId=" + history.at("/nextBeforeId").asLong() + "&pageSize=100");
        assertThat(oldest.at("/messages").size()).isEqualTo(55);
        assertThat(oldest.at("/hasMore").asBoolean()).isFalse();
        JsonNode next = read("c", user, id, "?afterId=" + cursor + "&pageSize=100");
        assertThat(next.at("/messages").size()).isEqualTo(100);
        assertThat(next.at("/hasMore").asBoolean()).isTrue();
        assertThat(next.at("/session/unread").asInt()).isEqualTo(105);
        JsonNode tail = read("c", user, id, "?afterId=" + next.at("/nextAfterId").asLong());
        assertThat(tail.at("/messages").size()).isEqualTo(5);
        assertThat(tail.at("/hasMore").asBoolean()).isFalse();
        assertThat(tail.at("/session/unread").asInt()).isZero();
        JsonNode idle = read("c", user, id, "?afterId=" + tail.at("/nextAfterId").asLong());
        assertThat(idle.at("/messages").size()).isZero();
        assertThat(idle.at("/nextAfterId")).isEqualTo(tail.at("/nextAfterId"));
    }

    @Test
    void merchantUsesSamePagingAndHistoryDoesNotAcknowledgeNewMessages() throws Exception {
        String user = registerUser();
        long id = start(user);
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        JsonNode empty = read("b", merchant, id, "");
        assertThat(empty.at("/messages").size()).isZero();
        assertThat(empty.at("/nextAfterId").asLong()).isZero();
        assertThat(empty.at("/nextBeforeId").isNull()).isTrue();
        seedMessages(id, 7, 1);
        jdbc.update("UPDATE consult_session SET merchant_unread=7 WHERE id=?", id);
        JsonNode first = read("b", merchant, id, "?afterId=0&pageSize=3");
        assertThat(first.at("/messages").size()).isEqualTo(3);
        assertThat(first.at("/hasMore").asBoolean()).isTrue();
        assertThat(first.at("/session/unread").asInt()).isEqualTo(7);
        JsonNode tail = read("b", merchant, id, "?afterId=" + first.at("/nextAfterId").asLong());
        assertThat(tail.at("/messages").size()).isEqualTo(4);
        assertThat(tail.at("/session/unread").asInt()).isZero();
        jdbc.update("UPDATE consult_session SET merchant_unread=1 WHERE id=?", id);
        JsonNode history = read("b", merchant, id, "?beforeId=" + tail.at("/nextBeforeId").asLong());
        assertThat(history.at("/messages").size()).isEqualTo(3);
        assertThat(history.at("/session/unread").asInt()).isEqualTo(1);
    }

    @Test
    void rejectsInvalidCursorsAndCrossUserRegionOrMerchantAccess() throws Exception {
        String user = registerUser();
        long id = start(user);
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        for (String side : new String[]{"c", "b"}) {
            String token = side.equals("c") ? user : merchant;
            for (String query : new String[]{"?beforeId=1&afterId=0", "?beforeId=0", "?afterId=-1", "?pageSize=0", "?pageSize=101"}) {
                mockMvc.perform(get("/api/" + side + "/v1/consult/sessions/" + id + "/messages" + query)
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                        .andExpect(status().isBadRequest());
            }
            mockMvc.perform(get("/api/" + side + "/v1/consult/sessions/" + id + "/messages?afterId=0")
                    .header("Authorization", bearer(token)).header("X-Region", "EU"))
                    .andExpect(status().is(side.equals("b") ? 403 : 404));
        }
        mockMvc.perform(get("/api/c/v1/consult/sessions/" + id + "/messages?beforeId=999999")
                .header("Authorization", bearer(registerUser())).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
        // Re-scope an existing merchant operator: list, reads and writes must all respect it.
        jdbc.update("UPDATE merchant_operator SET shop_scope_type=2 WHERE id=11001");
        mockMvc.perform(get("/api/b/v1/consult/sessions").header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.list.length()").value(0));
        mockMvc.perform(get("/api/b/v1/consult/sessions/" + id + "/messages?afterId=0")
                .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/b/v1/consult/sessions/" + id + "/messages")
                .header("Authorization", bearer(merchant)).header("X-Region", "CN")
                .contentType(MediaType.APPLICATION_JSON).content("{\"content\":\"forbidden\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.NOT_SUPPORTED)
    void allocatesMessageIdsOnlyAfterEarlierSessionWriterCommits() throws Exception {
        String user = registerUser();
        long id = start(user);
        var locked = new java.util.concurrent.CountDownLatch(1);
        var release = new java.util.concurrent.CountDownLatch(1);
        var executor = java.util.concurrent.Executors.newFixedThreadPool(2);
        try {
            var first = executor.submit(() -> new org.springframework.transaction.support.TransactionTemplate(transactionManager).execute(tx -> {
                consultMapper.lockSession(id);
                locked.countDown();
                try {
                    if (!release.await(10, java.util.concurrent.TimeUnit.SECONDS)) throw new IllegalStateException("writer gate timed out");
                } catch (InterruptedException e) { Thread.currentThread().interrupt(); throw new IllegalStateException(e); }
                jdbc.update("INSERT INTO consult_message(session_id,region,sender_type,sender_id,content) VALUES(?,'CN',2,11001,'slow first writer')", id);
                return jdbc.queryForObject("SELECT id FROM consult_message WHERE session_id=? AND content='slow first writer'", Long.class, id);
            }));
            assertThat(locked.await(5, java.util.concurrent.TimeUnit.SECONDS)).isTrue();
            var next = executor.submit(() -> mockMvc.perform(post("/api/c/v1/consult/sessions/" + id + "/messages")
                    .header("Authorization", bearer(user)).header("X-Region", "CN")
                    .contentType(MediaType.APPLICATION_JSON).content("{\"content\":\"parallel second writer\"}"))
                    .andExpect(status().isOk()).andReturn());
            org.assertj.core.api.Assertions.assertThatThrownBy(() -> next.get(200, java.util.concurrent.TimeUnit.MILLISECONDS))
                    .isInstanceOf(java.util.concurrent.TimeoutException.class);
            release.countDown();
            long firstId = first.get(10, java.util.concurrent.TimeUnit.SECONDS);
            long secondId = objectMapper.readTree(next.get(10, java.util.concurrent.TimeUnit.SECONDS).getResponse().getContentAsString()).at("/data/id").asLong();
            assertThat(secondId).isGreaterThan(firstId);
            JsonNode page = read("c", user, id, "?afterId=" + firstId);
            assertThat(page.at("/messages").size()).isEqualTo(1);
            assertThat(page.at("/messages/0/id").asLong()).isEqualTo(secondId);
        } finally {
            release.countDown();
            executor.shutdownNow();
            executor.awaitTermination(10, java.util.concurrent.TimeUnit.SECONDS);
        }
    }

    private long start(String user) throws Exception {
        var result = mockMvc.perform(post("/api/c/v1/consult/sessions")
                .header("Authorization", bearer(user)).header("X-Region", "CN")
                .contentType(MediaType.APPLICATION_JSON).content("{\"shopId\":10001}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    @Test
    void sessionPagesAreBoundedStableAcrossTimestampTiesAndFilteredForEachViewer() throws Exception {
        String user = registerUser();
        long firstId = start(user);
        long userId = jdbc.queryForObject("SELECT user_id FROM consult_session WHERE id=?", Long.class, firstId);
        long merchantId = jdbc.queryForObject("SELECT merchant_id FROM consult_session WHERE id=?", Long.class, firstId);
        jdbc.update("UPDATE consult_session SET merchant_unread=0 WHERE merchant_id=? AND user_id<>?", merchantId, userId);
        jdbc.update("UPDATE consult_session SET updated_at='2026-01-01 10:00:00', user_unread=1,merchant_unread=0 WHERE id=?", firstId);
        for (int i = 0; i < 44; i++) {
            jdbc.update("INSERT INTO consult_session(region,user_id,shop_id,merchant_id,updated_at,user_unread,merchant_unread) VALUES('CN',?,?,?,'2026-01-01 10:00:00',?,?)",
                    userId, 900000 + i, merchantId, i % 2, (i + 1) % 2);
        }
        JsonNode page = sessionPage("c", user, "");
        assertThat(page.path("list").size()).isEqualTo(20);
        var ids = new java.util.ArrayList<Long>();
        while (true) {
            page.path("list").forEach(row -> ids.add(row.path("id").asLong()));
            if (!page.path("hasMore").asBoolean()) break;
            page = sessionPage("c", user, "?beforeId=" + page.path("nextBeforeId").asLong()
                    + "&beforeUpdatedAt=" + page.path("nextBeforeUpdatedAt").asText());
        }
        assertThat(ids).hasSize(45).doesNotHaveDuplicates().isSortedAccordingTo(java.util.Comparator.reverseOrder());
        assertThat(page.path("nextBeforeId").isNull()).isTrue();
        assertThat(page.path("nextBeforeUpdatedAt").isNull()).isTrue();
        assertThat(sessionPage("c", user, "?pageSize=100").path("list").size()).isEqualTo(45);
        JsonNode userUnread = sessionPage("c", user, "?unreadOnly=true&pageSize=100");
        assertThat(userUnread.path("list").size()).isEqualTo(23);
        for (JsonNode row : userUnread.path("list")) assertThat(row.path("unread").asInt()).isPositive();
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        JsonNode merchantUnread = sessionPage("b", merchant, "?unreadOnly=true&pageSize=100");
        assertThat(merchantUnread.path("list").size()).isEqualTo(22);
        for (JsonNode row : merchantUnread.path("list")) assertThat(row.path("unread").asInt()).isPositive();
        var timestamp = jdbc.queryForObject("SELECT updated_at FROM consult_session WHERE id=?", java.sql.Timestamp.class, firstId);
        read("c", user, firstId, "");
        assertThat(jdbc.queryForObject("SELECT updated_at FROM consult_session WHERE id=?", java.sql.Timestamp.class, firstId)).isEqualTo(timestamp);
        assertThat(sessionPage("c", user, "?unreadOnly=true&pageSize=100").path("list").size()).isEqualTo(22);
        assertThat(sessionPage("c", registerUser(), "").path("list").size()).isZero();
    }

    @Test
    void sessionPaginationRejectsInvalidBoundariesAndPreservesShopAndRegionScopes() throws Exception {
        String user = registerUser();
        long id = start(user);
        String merchant = loginMerchant("merchant_cn_hotpot@example.com", "merchant123456");
        for (String side : new String[]{"c", "b"}) {
            String token = side.equals("c") ? user : merchant;
            for (String query : new String[]{"?beforeId=1", "?beforeUpdatedAt=2026-01-01T00:00:00", "?beforeId=0&beforeUpdatedAt=2026-01-01T00:00:00", "?beforeId=1&beforeUpdatedAt=invalid", "?pageSize=0", "?pageSize=101"}) {
                mockMvc.perform(get("/api/" + side + "/v1/consult/sessions" + query)
                        .header("Authorization", bearer(token)).header("X-Region", "CN")).andExpect(status().isBadRequest());
            }
        }
        mockMvc.perform(get("/api/c/v1/consult/sessions?unreadOnly=true")
                .header("Authorization", bearer(user)).header("X-Region", "EU"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.list.length()").value(0));
        jdbc.update("UPDATE merchant_operator SET shop_scope_type=2 WHERE id=11001");
        assertThat(sessionPage("b", merchant, "?unreadOnly=true").path("list").size()).isZero();
        jdbc.update("INSERT INTO merchant_operator_shop(operator_id,shop_id) VALUES(11001,10001)");
        jdbc.update("UPDATE consult_session SET merchant_unread=1 WHERE id=?", id);
        sqlSession.clearCache(); // Direct JDBC fixture edits bypass MyBatis cache invalidation.
        assertThat(sessionPage("b", merchant, "?unreadOnly=true").path("list").get(0).path("id").asLong()).isEqualTo(id);
    }

    private JsonNode sessionPage(String side, String token, String query) throws Exception {
        var result = mockMvc.perform(get("/api/" + side + "/v1/consult/sessions" + query)
                .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).path("data");
    }

    private JsonNode read(String side, String token, long id, String query) throws Exception {
        var result = mockMvc.perform(get("/api/" + side + "/v1/consult/sessions/" + id + "/messages" + query)
                .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data");
    }

    private void seedMessages(long sessionId, int count, int senderType) {
        var rows = new java.util.ArrayList<Object[]>();
        for (int i = 0; i < count; i++) rows.add(new Object[]{sessionId, senderType, "message-" + i});
        jdbc.batchUpdate("INSERT INTO consult_message(session_id,region,sender_type,sender_id,content) VALUES(?,'CN',?,11001,?)", rows);
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
