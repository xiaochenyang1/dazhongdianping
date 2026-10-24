package com.tuowei.dazhongdianping.module.search.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.request;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.search.gateway.ElasticsearchShopSearchGateway;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocument;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/** Real deal transactions and durable outbox dispatch; only the ES transport is replaced. */
@SpringBootTest(properties = {
        "app.search.provider=elasticsearch",
        "app.search.sync-initial-delay-ms=3600000"
})
@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class DealSearchSyncIntegrationTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired ShopSearchSyncOutboxService outbox;
    @Autowired PlatformTransactionManager transactionManager;
    @MockBean ElasticsearchShopSearchGateway gateway;

    private final Map<Long, ShopSearchDocument> indexed = new HashMap<>();
    private String merchantToken;
    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        jdbc.update("DELETE FROM shop_search_sync_task");
        indexed.clear();
        doAnswer(invocation -> {
            ShopSearchDocument document = invocation.getArgument(0);
            indexed.put(document.getId(), document);
            return null;
        }).when(gateway).indexDocument(any());
        merchantToken = call(HttpMethod.POST, "/api/b/v1/auth/login", "", Map.of(
                "account", "merchant_eu_sichuan@example.com", "password", "merchant123456"
        )).path("accessToken").asText();
        adminToken = call(HttpMethod.POST, "/api/admin/v1/auth/login", "", Map.of(
                "account", "admin", "password", "admin123456"
        )).path("accessToken").asText();
    }

    @Test
    void shouldRefreshTitlesAcrossCreationAuditResubmissionAndShelfChanges() throws Exception {
        long id = createDeal("AuroraTasting", 20001L);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).doesNotContain("AuroraTasting");

        audit(id, true);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).doesNotContain("AuroraTasting");
        shelf(id, 1);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).contains("AuroraTasting");

        updateDeal(id, "TruffleBanquet", 20001L);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).doesNotContain("AuroraTasting", "TruffleBanquet");
        audit(id, true);
        shelf(id, 1);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).contains("TruffleBanquet").doesNotContain("AuroraTasting");

        shelf(id, 0);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).doesNotContain("TruffleBanquet");
        updateDeal(id, "RejectedMenu", 20001L);
        sync();
        audit(id, false);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).doesNotContain("RejectedMenu");
    }

    @Test
    void shouldRefreshBothShopsWhenAnUnsoldDealMoves() throws Exception {
        // A second Paris branch owned by the same merchant in this isolated test database.
        jdbc.update("UPDATE shop SET merchant_id=2001,category_id=201,city_id=101,area_id=1011 WHERE id=20002");
        long id = createDeal("MovingFeast", 20001L);
        audit(id, true);
        shelf(id, 1);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).contains("MovingFeast");

        updateDeal(id, "MovingFeast", 20002L);
        assertThat(jdbc.queryForList("SELECT shop_id FROM shop_search_sync_task ORDER BY shop_id", Long.class))
                .containsExactly(20001L, 20002L);
        sync();
        assertThat(indexed.get(20001L).getDealTitles()).doesNotContain("MovingFeast");
        assertThat(indexed.get(20002L).getDealTitles()).doesNotContain("MovingFeast");

        audit(id, true);
        shelf(id, 1);
        sync();
        assertThat(indexed.get(20002L).getDealTitles()).contains("MovingFeast");
        assertThat(indexed.get(20001L).getDealTitles()).doesNotContain("MovingFeast");
    }

    @Test
    void shouldNotLeaveAnIndexTaskWhenTheDealTransactionRollsBack() {
        new TransactionTemplate(transactionManager).executeWithoutResult(transaction -> {
            try {
                createDeal("RollbackDinner", 20001L);
                transaction.setRollbackOnly();
            } catch (Exception exception) {
                throw new IllegalStateException(exception);
            }
        });
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM deal WHERE title='RollbackDinner'", Integer.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM shop_search_sync_task", Integer.class)).isZero();
        assertThat(outbox.dispatchDueTasks()).isZero();
        verifyNoInteractions(gateway);
    }

    private void sync() {
        assertThat(outbox.dispatchDueTasks()).isPositive();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM shop_search_sync_task", Integer.class)).isZero();
    }

    private long createDeal(String title, long shopId) throws Exception {
        return call(HttpMethod.POST, "/api/b/v1/deals", merchantToken, dealBody(title, shopId)).path("id").asLong();
    }

    private void updateDeal(long id, String title, long shopId) throws Exception {
        call(HttpMethod.PUT, "/api/b/v1/deals/" + id, merchantToken, dealBody(title, shopId));
    }

    private void shelf(long id, int value) throws Exception {
        call(HttpMethod.PUT, "/api/b/v1/deals/" + id + "/status", merchantToken, Map.of("status", value));
    }

    private void audit(long id, boolean pass) throws Exception {
        Long taskId = jdbc.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=2 AND biz_id=? AND status=0", Long.class, id);
        call(HttpMethod.POST, "/api/admin/v1/audit/tasks/" + taskId + (pass ? "/pass" : "/reject"),
                adminToken, pass ? Map.of("remark", "checked") : Map.of("reason", "Revise the menu"));
    }

    private Map<String, Object> dealBody(String title, long shopId) {
        Map<String, Object> body = new HashMap<>();
        body.put("shopId", shopId);
        body.put("type", 1);
        body.put("title", title);
        body.put("coverImage", "https://files.example/deals/dinner.jpg");
        body.put("price", new BigDecimal("49.90"));
        body.put("originalPrice", new BigDecimal("68.00"));
        body.put("currency", "EUR");
        body.put("stock", 20);
        body.put("validStart", LocalDate.now().minusDays(1).toString());
        body.put("validEnd", LocalDate.now().plusMonths(1).toString());
        body.put("rules", "Reservation required");
        body.put("items", List.of(Map.of("name", "Main", "quantity", 2, "price", 0, "sort", 1)));
        return body;
    }

    private JsonNode call(HttpMethod method, String path, String token, Object body) throws Exception {
        var builder = request(method, path).header("X-Region", "EU");
        if (!token.isBlank()) builder.header("Authorization", "Bearer " + token);
        if (body != null) builder.contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsBytes(body));
        var response = mvc.perform(builder).andExpect(status().isOk()).andReturn().getResponse();
        JsonNode result = json.readTree(response.getContentAsString());
        assertThat(result.path("code").asInt()).isZero();
        return result.path("data");
    }
}
