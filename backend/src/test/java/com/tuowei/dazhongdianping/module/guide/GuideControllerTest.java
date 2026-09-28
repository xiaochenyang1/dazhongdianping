package com.tuowei.dazhongdianping.module.guide;

import static org.hamcrest.Matchers.hasItem;
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
class GuideControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void publishedGuidesAreRegionalAndDetailIncludesSections() throws Exception {
        mockMvc.perform(get("/api/c/v1/guides").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==9001)].title", hasItem("徐汇周末火锅怎么选")))
                .andExpect(jsonPath("$.data.list[?(@.id==9002)].id").doesNotExist());

        mockMvc.perform(get("/api/c/v1/guides").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==9002)].title", hasItem("Paris Chinese dining weekend")))
                .andExpect(jsonPath("$.data.list[?(@.id==9001)].id").doesNotExist());

        mockMvc.perform(get("/api/c/v1/guides/{id}", 9001).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.sections[0].heading").value("聚餐首选"))
                .andExpect(jsonPath("$.data.sections[0].shopId").value(10001))
                .andExpect(jsonPath("$.data.sections[0].sortNo").value(1));

        mockMvc.perform(get("/api/c/v1/guides/{id}", 9002).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/c/v1/guides/{id}", 99999999L).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
    }

    @Test
    void adminSavesReplacesSectionsAndPublishes() throws Exception {
        String admin = adminLogin();
        MvcResult created = mockMvc.perform(post("/api/admin/v1/guides")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "草稿攻略",
                                  "summary": "还没发",
                                  "coverUrl": "",
                                  "cityId": 1,
                                  "status": 1,
                                  "sections": [
                                    {"heading": "后写", "body": "第二条", "shopId": 10001, "sortNo": 2},
                                    {"heading": "先写", "body": "第一条", "shopId": 10002, "sortNo": 1}
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.guide_saved"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.sections[0].heading").value("先写"))
                .andExpect(jsonPath("$.data.sections[0].sortNo").value(1))
                .andExpect(jsonPath("$.data.sections[1].heading").value("后写"))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/c/v1/guides/{id}", id).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/c/v1/guides").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + id + ")].id").doesNotExist());

        mockMvc.perform(get("/api/admin/v1/guides")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + id + ")].status", hasItem(1)))
                .andExpect(jsonPath("$.data.list[?(@.id==9001)].status", hasItem(2)));

        mockMvc.perform(put("/api/admin/v1/guides/{id}", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "草稿攻略",
                                  "summary": "改过章节",
                                  "coverUrl": "https://cdn.example.com/guide.png",
                                  "cityId": 1,
                                  "status": 1,
                                  "sections": [
                                    {"heading": "只剩这一节", "body": "新正文", "shopId": 10001, "sortNo": 1}
                                  ]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.guide_saved"))
                .andExpect(jsonPath("$.data.sections.length()").value(1))
                .andExpect(jsonPath("$.data.sections[0].heading").value("只剩这一节"))
                .andExpect(jsonPath("$.data.sections[?(@.heading=='先写')].heading").doesNotExist());

        mockMvc.perform(post("/api/admin/v1/guides/{id}/status", id)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.guide_saved"))
                .andExpect(jsonPath("$.data.status").value(2));

        mockMvc.perform(get("/api/c/v1/guides/{id}", id).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("草稿攻略"))
                .andExpect(jsonPath("$.data.sections[0].shopId").value(10001));

        mockMvc.perform(post("/api/admin/v1/guides").header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"title\":\"无权限\"}"))
                .andExpect(status().isUnauthorized());
    }

    private String adminLogin() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
