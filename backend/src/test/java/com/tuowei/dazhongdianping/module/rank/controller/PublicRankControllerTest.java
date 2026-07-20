package com.tuowei.dazhongdianping.module.rank.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class PublicRankControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void shouldListPublishedRanksByCityAndCategory() throws Exception {
        mockMvc.perform(get("/api/c/v1/ranks")
                        .header("X-Region", "CN")
                        .param("cityId", "1")
                        .param("categoryId", "102"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(30001))
                .andExpect(jsonPath("$.data[0].typeText").value("必吃榜"));
    }

    @Test
    void shouldKeepRankDataRegionIsolated() throws Exception {
        mockMvc.perform(get("/api/c/v1/ranks")
                        .header("X-Region", "EU")
                        .param("cityId", "101"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(3))
                .andExpect(jsonPath("$.data[0].region").value("EU"));

        mockMvc.perform(get("/api/c/v1/ranks/30001").header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldReturnRankedShopSnapshot() throws Exception {
        mockMvc.perform(get("/api/c/v1/ranks/30001").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("上海火锅必吃榜"))
                .andExpect(jsonPath("$.data.items[0].position").value(1))
                .andExpect(jsonPath("$.data.items[0].shop.id").value(10001))
                .andExpect(jsonPath("$.data.items[0].reason").isNotEmpty());
    }
}
