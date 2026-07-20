package com.tuowei.dazhongdianping.module.admin.circle;

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

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminCircleControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void shouldCreateUpdateListAndDisableCircleWithinCurrentRegion() throws Exception {
        String token = loginToken();
        MvcResult created = mockMvc.perform(post("/api/admin/v1/circles")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"巴黎生活圈","description":"法国华人本地生活","coverUrl":"https://example.com/paris.jpg","sort":30}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.region").value("EU"))
                .andExpect(jsonPath("$.data.name").value("巴黎生活圈"))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(put("/api/admin/v1/circles/{id}", id)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name":"巴黎吃喝圈","description":"更新后的介绍","coverUrl":"","sort":40}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("巴黎吃喝圈"))
                .andExpect(jsonPath("$.data.sort").value(40));

        mockMvc.perform(put("/api/admin/v1/circles/{id}/status", id)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));

        mockMvc.perform(get("/api/admin/v1/circles").header("Authorization", bearer(token)).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].name").value("巴黎吃喝圈"));
    }

    @Test
    void shouldRejectDuplicateNameAndCrossRegionMutation() throws Exception {
        String token = loginToken();
        create(token, "CN", "上海咖啡圈").andExpect(status().isOk());
        create(token, "CN", "上海咖啡圈").andExpect(status().isConflict());
        MvcResult eu = create(token, "EU", "伦敦咖啡圈").andExpect(status().isOk()).andReturn();
        long euId = objectMapper.readTree(eu.getResponse().getContentAsString()).at("/data/id").asLong();
        mockMvc.perform(put("/api/admin/v1/circles/{id}/status", euId)
                        .header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":2}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldExposeCircleManagementMenu() throws Exception {
        String token = loginToken();
        mockMvc.perform(get("/api/admin/v1/menus").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[3].children[2].path").value("/operations/circles"));
    }

    private org.springframework.test.web.servlet.ResultActions create(String token, String region, String name) throws Exception {
        return mockMvc.perform(post("/api/admin/v1/circles").header("Authorization", bearer(token)).header("X-Region", region)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"" + name + "\",\"description\":\"测试圈子\",\"coverUrl\":\"\",\"sort\":10}"));
    }
    private String loginToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }
    private String bearer(String token) { return "Bearer " + token; }
}
