package com.tuowei.dazhongdianping.module.browse.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
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
    void shouldRecommendNearbySimilarShopsWithinCurrentRegion() throws Exception {
        jdbcTemplate.update("INSERT INTO category(id, parent_id, region, name, sort_no, status) VALUES (99005, 0, 'CN', '停用推荐分类', 99, 0)");
        insertShop(99001L, 102L, 1L, 11L, "CN", "近处同类火锅", 31.1960000, 121.4370000, 1, false);
        insertShop(99002L, 102L, 1L, 11L, "CN", "远处同类火锅", 31.2400000, 121.4900000, 1, false);
        insertShop(99003L, 102L, 1L, 11L, "EU", "跨区同类火锅", 31.1953000, 121.4366000, 1, false);
        insertShop(99004L, 102L, 1L, 11L, "CN", "停用同类火锅", 31.1954000, 121.4367000, 0, false);
        insertShop(99005L, 99005L, 1L, 11L, "CN", "停用分类门店", 31.1955000, 121.4368000, 1, false);

        mockMvc.perform(get("/api/c/v1/shops/10001/similar").param("limit", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].id").value(99001))
                .andExpect(jsonPath("$.data[0].distanceMeters").isNumber())
                .andExpect(jsonPath("$.data[1].id").value(99002))
                .andExpect(jsonPath("$.data[?(@.id == 10001)]").isEmpty())
                .andExpect(jsonPath("$.data[?(@.id == 99003)]").isEmpty())
                .andExpect(jsonPath("$.data[?(@.id == 99004)]").isEmpty());

        mockMvc.perform(get("/api/c/v1/shops/10001/similar").param("limit", "12"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == 99005)]").isEmpty());
    }

    @Test
    void shouldRankAllEligibleSimilarShopsBeforeApplyingTheResponseLimit() throws Exception {
        for (long id = 98000L; id < 98060L; id++) {
            insertShop(id, 102L, 1L, 11L, "CN", "远处候选-" + id,
                    30.0000000, 120.0000000, 1, false);
        }
        insertShop(99999L, 102L, 1L, 11L, "CN", "第六十一条近处候选",
                31.1953000, 121.4366000, 1, false);

        mockMvc.perform(get("/api/c/v1/shops/10001/similar").param("limit", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(99999));
    }

    @Test
    void shouldRejectSimilarShopLimitAboveTwelve() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops/10001/similar").param("limit", "13"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("limit 最大为 12"));
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
    void shouldSortPublicShopReviewsByPopularity() throws Exception {
        deleteCnShopReviews();
        insertPublicReview(92001L, "CN", LocalDateTime.of(2026, 7, 1, 12, 0), new BigDecimal("4.0"), 2, 1);
        insertPublicReview(92002L, "CN", LocalDateTime.of(2026, 6, 1, 12, 0), new BigDecimal("3.5"), 10, 5);

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("sort", "popular")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].id").value(92002))
                .andExpect(jsonPath("$.data.list[1].id").value(92001));
    }

    @Test
    void shouldSortPublicShopReviewsByScore() throws Exception {
        deleteCnShopReviews();
        insertPublicReview(92101L, "CN", LocalDateTime.of(2026, 7, 5, 12, 0), new BigDecimal("3.8"), 20, 0);
        insertPublicReview(92102L, "CN", LocalDateTime.of(2026, 6, 5, 12, 0), new BigDecimal("4.9"), 0, 0);

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("sort", "score")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].id").value(92102))
                .andExpect(jsonPath("$.data.list[1].id").value(92101));
    }

    @Test
    void shouldFilterPublicShopReviewsByMinimumScoreAndImages() throws Exception {
        deleteCnShopReviews();
        insertPublicReview(92201L, "CN", LocalDateTime.of(2026, 7, 3, 12, 0), new BigDecimal("4.8"), 0, 0);
        insertPublicReview(92202L, "CN", LocalDateTime.of(2026, 7, 2, 12, 0), new BigDecimal("4.7"), 0, 0);
        insertPublicReview(92203L, "CN", LocalDateTime.of(2026, 7, 1, 12, 0), new BigDecimal("3.0"), 0, 0);
        jdbcTemplate.update("INSERT INTO review_image(id, review_id, url, media_type, sort_no) VALUES (?, ?, ?, 1, 0)",
                92301L, 92201L, "https://files.example/review-92201.jpg");
        jdbcTemplate.update("INSERT INTO review_image(id, review_id, url, media_type, sort_no) VALUES (?, ?, ?, 1, 0)",
                92302L, 92203L, "https://files.example/review-92203.jpg");

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("minScore", "4")
                        .param("hasImages", "true")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(92201));

        mockMvc.perform(get("/api/c/v1/shops/10001/reviews")
                        .param("minScore", "4")
                        .param("hasImages", "false")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(92202));
    }

    @Test
    void shouldRejectUnsupportedPublicShopReviewSort() throws Exception {
        mockMvc.perform(get("/api/c/v1/shops/10001/reviews").param("sort", "random"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
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
    void shouldHideDisabledGeoDataWithoutBreakingHistoricalShopDetails() throws Exception {
        jdbcTemplate.update("UPDATE category SET status=0 WHERE id IN (202, 210)");
        jdbcTemplate.update("UPDATE city SET status=0 WHERE id=102");
        jdbcTemplate.update("UPDATE area SET status=0 WHERE id=1021");

        mockMvc.perform(get("/api/c/v1/categories").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[*].children[?(@.id == 202)]").isEmpty())
                .andExpect(jsonPath("$.data[?(@.id == 210)]").isEmpty());
        mockMvc.perform(get("/api/c/v1/cities").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == 102)]").isEmpty());
        mockMvc.perform(get("/api/c/v1/cities/{cityId}/areas", 102L).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());

        mockMvc.perform(get("/api/c/v1/shops").header("X-Region", "EU")
                        .param("categoryId", "202"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
        mockMvc.perform(get("/api/c/v1/shops").header("X-Region", "EU")
                        .param("cityId", "102"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
        mockMvc.perform(get("/api/c/v1/shops").header("X-Region", "EU")
                        .param("areaId", "1021"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
        mockMvc.perform(get("/api/c/v1/shops").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list.length()").value(1))
                .andExpect(jsonPath("$.data.hasMore").value(false));

        mockMvc.perform(get("/api/c/v1/search/suggest").header("X-Region", "EU")
                        .param("kw", "Lifestyle"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());
        mockMvc.perform(get("/api/c/v1/search/suggest").header("X-Region", "EU")
                        .param("kw", "Mitte"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());
        mockMvc.perform(get("/api/c/v1/search/hot").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.term == 'Lifestyle')]").isEmpty())
                .andExpect(jsonPath("$.data[?(@.term == 'Breakfast')]").isEmpty());

        mockMvc.perform(get("/api/c/v1/shops/{shopId}", 20002L).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.categoryName").value("Cafe"))
                .andExpect(jsonPath("$.data.cityName").value("Berlin"))
                .andExpect(jsonPath("$.data.areaName").value("Mitte"));
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
        insertPublicReview(id, region, createdAt, new BigDecimal("4.5"), 0, 0);
    }

    private void insertPublicReview(long id,
                                    String region,
                                    LocalDateTime createdAt,
                                    BigDecimal score,
                                    int likeCount,
                                    int commentCount) {
        jdbcTemplate.update("""
                        INSERT INTO review(
                            id,
                            shop_id,
                            region,
                            user_name,
                            content,
                            score_overall,
                            like_count,
                            comment_count,
                            audit_status,
                            status,
                            created_at,
                            is_deleted
                        )
                        VALUES (?, 10001, ?, ?, ?, ?, ?, ?, 1, 1, ?, FALSE)
                        """,
                id,
                region,
                "分页测试用户-" + id,
                "用于验证公开点评分页顺序。",
                score,
                likeCount,
                commentCount,
                Timestamp.valueOf(createdAt));
    }

    private void deleteCnShopReviews() {
        jdbcTemplate.update("DELETE FROM review_image WHERE review_id IN (SELECT id FROM review WHERE shop_id=10001 AND region='CN')");
        jdbcTemplate.update("DELETE FROM review WHERE shop_id=10001 AND region='CN'");
    }

    private void insertShop(long id,
                            long categoryId,
                            long cityId,
                            long areaId,
                            String region,
                            String name,
                            double latitude,
                            double longitude,
                            int status,
                            boolean deleted) {
        jdbcTemplate.update("""
                        INSERT INTO shop(
                            id, merchant_id, category_id, city_id, area_id, latitude, longitude, region,
                            name, cover_url, phone, score, taste_score, env_score, service_score,
                            price_per_capita, currency, address, business_hours, summary, has_deal,
                            open_now, status, is_deleted, tags
                        )
                        VALUES (?, 1001, ?, ?, ?, ?, ?, ?, ?, ?, '', 4.5, 4.5, 4.5, 4.5,
                                100.00, ?, ?, '10:00-22:00', '相似推荐测试门店', FALSE, TRUE, ?, ?, '火锅,聚餐')
                        """,
                id,
                categoryId,
                cityId,
                areaId,
                latitude,
                longitude,
                region,
                name,
                "https://placehold.co/600x400?text=" + id,
                "EU".equals(region) ? "EUR" : "CNY",
                "测试地址-" + id,
                status,
                deleted);
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }
}
