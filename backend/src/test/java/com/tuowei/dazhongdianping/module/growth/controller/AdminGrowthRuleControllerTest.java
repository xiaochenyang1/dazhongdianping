package com.tuowei.dazhongdianping.module.growth.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional @SpringBootTest @AutoConfigureMockMvc
class AdminGrowthRuleControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void shouldListCreateAndUpdateGrowthRules() throws Exception {
        String token = login();
        mockMvc.perform(get("/api/admin/v1/growth/rules").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rules[0].action").value("review_create"))
                .andExpect(jsonPath("$.data.levels.length()").value(8));

        MvcResult created = mockMvc.perform(post("/api/admin/v1/growth/rules").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"favorite_shop\",\"actionName\":\"收藏门店\",\"growthValue\":1,\"points\":1,\"dailyLimit\":10,\"enabled\":true}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.action").value("favorite_shop")).andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();
        mockMvc.perform(put("/api/admin/v1/growth/rules/{id}", id).header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"favorite_shop\",\"actionName\":\"收藏门店\",\"growthValue\":2,\"points\":0,\"dailyLimit\":5,\"enabled\":false}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.growthValue").value(2)).andExpect(jsonPath("$.data.enabled").value(false));

        mockMvc.perform(put("/api/admin/v1/growth/rules/levels/2").header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"minGrowth\":30,\"levelName\":\"进阶探索者\",\"icon\":\"lv2.svg\",\"privilegeJson\":\"{}\",\"enabled\":true}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.minGrowth").value(30));
    }

    private String login() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }
    private String bearer(String token) { return "Bearer " + token; }
}
