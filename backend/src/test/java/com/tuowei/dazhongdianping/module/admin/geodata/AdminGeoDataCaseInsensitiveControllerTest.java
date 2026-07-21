package com.tuowei.dazhongdianping.module.admin.geodata;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
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
class AdminGeoDataCaseInsensitiveControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String token;

    @BeforeEach
    void login() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        token = objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken").asText();
    }

    @Test
    void shouldRejectCategoryNameCaseVariants() throws Exception {
        mockMvc.perform(post("/api/admin/v1/categories")
                        .header("Authorization", bearer())
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"parentId\":0,\"name\":\"dining\",\"sortNo\":99}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("当前父分类下已存在同名分类"));
    }

    @Test
    void shouldRejectCityNameCaseVariants() throws Exception {
        mockMvc.perform(post("/api/admin/v1/cities")
                        .header("Authorization", bearer())
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"PARIS-LOWER\",\"name\":\"paris\",\"sortNo\":99}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("当前区域已存在同名城市"));
    }

    @Test
    void shouldRejectAreaNameCaseVariants() throws Exception {
        mockMvc.perform(post("/api/admin/v1/areas")
                        .header("Authorization", bearer())
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":101,\"name\":\"le marais\",\"sortNo\":99}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("当前城市已存在同名商圈"));
    }

    private String bearer() {
        return "Bearer " + token;
    }
}
