package com.tuowei.dazhongdianping.module.marketing;

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
class AdminMarketingControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void adminListsCreatesAndUpdatesCouponTemplate() throws Exception {
        String token = adminToken();

        mockMvc.perform(get("/api/admin/v1/marketing/coupon-templates")
                        .header("Authorization", bearer(token)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(org.hamcrest.Matchers.greaterThanOrEqualTo(3)));

        MvcResult created = mockMvc.perform(post("/api/admin/v1/marketing/coupon-templates")
                        .header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"满200减50\",\"type\":1,\"thresholdAmount\":200,\"discountAmount\":50,"
                                + "\"currency\":\"CNY\",\"shopId\":0,\"totalQuantity\":500,\"perUserLimit\":2,"
                                + "\"validDays\":14,\"status\":1}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.marketing_coupon_created"))
                .andExpect(jsonPath("$.data.name").value("满200减50"))
                .andExpect(jsonPath("$.data.region").value("CN"))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(put("/api/admin/v1/marketing/coupon-templates/{id}", id)
                        .header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"满200减60\",\"type\":1,\"thresholdAmount\":200,\"discountAmount\":60,"
                                + "\"currency\":\"CNY\",\"shopId\":0,\"totalQuantity\":500,\"perUserLimit\":2,"
                                + "\"validDays\":14,\"status\":0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.marketing_coupon_saved"))
                .andExpect(jsonPath("$.data.discountAmount").value(60))
                .andExpect(jsonPath("$.data.status").value(0));
    }

    @Test
    void createRejectsInvalidPayload() throws Exception {
        String token = adminToken();
        mockMvc.perform(post("/api/admin/v1/marketing/coupon-templates")
                        .header("Authorization", bearer(token)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"type\":9,\"thresholdAmount\":0,\"discountAmount\":0,"
                                + "\"currency\":\"CN\",\"shopId\":0,\"totalQuantity\":0,\"perUserLimit\":1,"
                                + "\"validDays\":7,\"status\":1}"))
                .andExpect(status().isBadRequest());
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
