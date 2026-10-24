package com.tuowei.dazhongdianping.module.search.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class PublicSearchControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private SqlSessionTemplate sqlSession;

    @Test
    void shouldFindShopsByDealTitleWithoutDuplicatingShopResults() throws Exception {
        jdbc.update("""
                INSERT INTO deal(id,shop_id,merchant_id,region,title,price,original_price,currency,stock,audit_status,status)
                VALUES (41991,20001,2001,'EU','Dinner for Two special',32,48,'EUR',20,1,1),
                       (41992,10001,1001,'EU','Dinner for Two wrong region',32,48,'EUR',20,1,1)
                """);
        mockMvc.perform(get("/api/c/v1/search/shops").header("X-Region", "EU")
                        .param("keyword", "dINNeR for TWO").param("pageSize", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(20001))
                .andExpect(jsonPath("$.data.hasMore").value(false));
        mockMvc.perform(get("/api/c/v1/search/shops").header("X-Region", "CN")
                        .param("keyword", "Dinner for Two"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(0));
        mockMvc.perform(get("/api/c/v1/search/suggest").header("X-Region", "EU")
                        .param("kw", "Dinner for Two"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].refId").value(20001));
    }

    @ParameterizedTest
    @ValueSource(strings = {"audit_status=0", "audit_status=2", "status=0", "is_deleted=TRUE", "region='CN'"})
    void shouldExcludeNonPublicDealTitlesFromSearchAndSuggestions(String change) throws Exception {
        jdbc.update("UPDATE deal SET " + change + " WHERE id=41001");
        mockMvc.perform(get("/api/c/v1/search/shops").header("X-Region", "EU").param("keyword", "Dinner for Two"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(0));
        mockMvc.perform(get("/api/c/v1/search/suggest").header("X-Region", "EU").param("kw", "Dinner for Two"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    void shouldReflectRenamedTitlesAndHideInactiveShopsInMysqlSearch() throws Exception {
        jdbc.update("UPDATE deal SET title='Seasonal Tasting Menu' WHERE id=41001");
        mockMvc.perform(get("/api/c/v1/search/shops").header("X-Region", "EU").param("keyword", "Dinner for Two"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(0));
        mockMvc.perform(get("/api/c/v1/search/shops").header("X-Region", "EU").param("keyword", "Tasting Menu"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.list[0].id").value(20001));
        jdbc.update("UPDATE shop SET status=0 WHERE id=20001");
        sqlSession.clearCache();
        mockMvc.perform(get("/api/c/v1/search/shops").header("X-Region", "EU").param("keyword", "Tasting Menu"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(0));
    }

    @Test
    void shouldSearchShopsWithMysqlFallbackAndRegionIsolation() throws Exception {
        mockMvc.perform(get("/api/c/v1/search/shops")
                        .param("keyword", "火锅")
                        .param("minScore", "4.0")
                        .param("page", "1")
                        .param("pageSize", "12"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(10001))
                .andExpect(jsonPath("$.data.list[0].name").value("渝里火锅徐汇店"));

        mockMvc.perform(get("/api/c/v1/search/shops")
                        .header("X-Region", "EU")
                        .param("keyword", "火锅"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
    }

    @Test
    void shouldRejectDistanceSortWithoutCoordinates() throws Exception {
        mockMvc.perform(get("/api/c/v1/search/shops")
                        .param("sort", "distance"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("距离排序必须提供 lat 和 lng"));
    }

    @Test
    void shouldRecordSearchHistoryWhenLoggedInUserHitsSearchShops() throws Exception {
        String accessToken = loginDemoUser();

        mockMvc.perform(get("/api/c/v1/search/shops")
                        .header("Authorization", bearer(accessToken))
                        .param("keyword", " 火锅 "))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        // Guest search must not require login, and must not create history.
        mockMvc.perform(get("/api/c/v1/search/shops")
                        .param("keyword", "游客词"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/search/history")
                        .header("Authorization", bearer(accessToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].keyword").value("火锅"))
                .andExpect(jsonPath("$.data.list[0].region").value("CN"));
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
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
