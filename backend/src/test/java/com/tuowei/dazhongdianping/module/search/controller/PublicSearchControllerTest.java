package com.tuowei.dazhongdianping.module.search.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class PublicSearchControllerTest {

    @Autowired
    private MockMvc mockMvc;

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
}
