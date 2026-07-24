package com.tuowei.dazhongdianping.module.browse.controller;

import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class ShopBrowseHistoryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRecordListAndClearBrowseHistoryForLoggedInUser() throws Exception {
        String token = registerUser();

        mockMvc.perform(get("/api/c/v1/user/browse-history")
                        .header("X-Region", "CN"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(get("/api/c/v1/shops/10001")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(10001));

        mockMvc.perform(get("/api/c/v1/shops/10002")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk());

        // reopen 10001 to bump view_count and last_viewed_at
        mockMvc.perform(get("/api/c/v1/shops/10001")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/user/browse-history")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].shopId").value(10001))
                .andExpect(jsonPath("$.data.list[0].viewCount").value(2))
                .andExpect(jsonPath("$.data.list[*].shopId", hasItem(10002)));

        // guest view should not write history
        mockMvc.perform(get("/api/c/v1/shops/10001").header("X-Region", "CN"))
                .andExpect(status().isOk());

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM user_shop_browse_history",
                Integer.class
        );
        org.junit.jupiter.api.Assertions.assertEquals(2, count);

        mockMvc.perform(delete("/api/c/v1/user/browse-history/10002")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/user/browse-history")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].shopId").value(10001));

        mockMvc.perform(delete("/api/c/v1/user/browse-history")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/user/browse-history")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
    }

    private String registerUser() throws Exception {
        String account = "browse-history-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"browse-history-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
