package com.tuowei.dazhongdianping.module.browse.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class PublicBrowseControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldReturnCnShopsByDefaultRegion() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.list[0].name").value("渝里火锅徐汇店"));
    }

    @Test
    void shouldReturnEuShopsWhenRegionHeaderIsEu() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.list[0].name").value("Maison Sichuan Paris"));
    }

    @Test
    void shouldReturnShopDetail() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops/10001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("渝里火锅徐汇店"))
                .andExpect(jsonPath("$.data.photos.length()").value(2))
                .andExpect(jsonPath("$.data.recommendedDishes.length()").value(2));
    }

    @Test
    void shouldReturnShopCurrencyAndDetailPhoneForCurrentRegion() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].currency").value("CNY"));

        mockMvc.perform(get("/api/c/v1/shops/10001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.currency").value("CNY"))
                .andExpect(jsonPath("$.data.phone").value("021-61008888"));

        mockMvc.perform(get("/api/c/v1/shops").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].currency").value("EUR"));

        mockMvc.perform(get("/api/c/v1/shops/20001").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.currency").value("EUR"))
                .andExpect(jsonPath("$.data.phone").value("+33142345678"));
    }

    @Test
    void shouldPageShopReviewsInStableDescendingOrder() throws Exception {
        insertPublicReview(91001L, "CN", LocalDateTime.of(2026, 7, 5, 12, 0));
        insertPublicReview(91002L, "CN", LocalDateTime.of(2026, 7, 5, 12, 0));
        insertPublicReview(91003L, "CN", LocalDateTime.of(2026, 7, 4, 12, 0));

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("page", "1")
                        .param("pageSize", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(91002))
                .andExpect(jsonPath("$.data.list[1].id").value(91001))
                .andExpect(jsonPath("$.data.total").value(4))
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.pageSize").value(2))
                .andExpect(jsonPath("$.data.hasMore").value(true));

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("page", "2")
                        .param("pageSize", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(91003))
                .andExpect(jsonPath("$.data.list[1].id").value(1))
                .andExpect(jsonPath("$.data.total").value(4))
                .andExpect(jsonPath("$.data.page").value(2))
                .andExpect(jsonPath("$.data.pageSize").value(2))
                .andExpect(jsonPath("$.data.hasMore").value(false));
    }

    @Test
    void shouldKeepShopReviewsIsolatedByRegion() throws Exception {
        insertPublicReview(91999L, "EU", LocalDateTime.of(2026, 7, 6, 12, 0));

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("page", "1")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(1));
    }

    @Test
    void shouldRejectShopReviewPageSizeAboveFifty() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("pageSize", "51"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("pageSize 最大为 50"));
    }

    @Test
    void shouldRejectNonNumericShopReviewPage() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("page", "abc"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("请求参数不合法"));
    }

    @Test
    void shouldRejectDecimalShopReviewPageSize() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("pageSize", "1.5"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("请求参数不合法"));
    }

    @Test
    void shouldReturnSearchSuggestionsFromCurrentRegion() throws Exception {
        mockMvc.perform(get("/api/c/v1/search/suggest").param("kw", "火锅"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data[0].term").value("渝里火锅徐汇店"))
                .andExpect(jsonPath("$.data[0].type").value("shop"))
                .andExpect(jsonPath("$.data[0].refId").value(10001));

        mockMvc.perform(get("/api/c/v1/search/suggest")
                        .header("X-Region", "EU")
                        .param("kw", "火锅"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    void shouldReturnHotSearchWordsFromCurrentRegion() throws Exception {
        mockMvc.perform(get("/api/c/v1/search/hot"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data[0].term").value("火锅"))
                .andExpect(jsonPath("$.data[0].score").value(3));

        mockMvc.perform(get("/api/c/v1/search/hot").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].term").value("Cafe"));
    }

    @Test
    void shouldRecordListAndClearSearchHistoryForLoggedInUser() throws Exception {
        String accessToken = loginDemoUser();

        mockMvc.perform(get("/api/c/v1/shops")
                        .header("Authorization", bearer(accessToken))
                        .param("keyword", " 火锅 "))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        mockMvc.perform(get("/api/c/v1/search/history")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.list[0].keyword").value("火锅"))
                .andExpect(jsonPath("$.data.list[0].region").value("CN"))
                .andExpect(jsonPath("$.data.total").value(1));

        mockMvc.perform(delete("/api/c/v1/search/history")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        mockMvc.perform(get("/api/c/v1/search/history")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
    }

    private String loginDemoUser() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/login/password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "demo.cn@example.com",
                                  "password": "Demo123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();
        return readText(result, "/data/accessToken");
    }

    private void insertPublicReview(long id, String region, LocalDateTime createdAt) {
        jdbcTemplate.update("""
                        INSERT INTO review(
                            id,
                            shop_id,
                            region,
                            user_name,
                            content,
                            score_overall,
                            audit_status,
                            status,
                            created_at,
                            is_deleted
                        )
                        VALUES (?, 10001, ?, ?, ?, 4.5, 1, 1, ?, FALSE)
                        """,
                id,
                region,
                "分页测试用户-" + id,
                "用于验证公开点评分页顺序。",
                Timestamp.valueOf(createdAt));
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }
}
