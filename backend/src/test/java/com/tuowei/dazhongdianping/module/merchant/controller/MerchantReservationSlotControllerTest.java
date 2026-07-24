package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
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
class MerchantReservationSlotControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldCreateListUpdateAndDisableReservationSlots() throws Exception {
        String token = merchantToken();
        LocalDate date = LocalDate.now().plusDays(3);

        MvcResult created = mockMvc.perform(post("/api/b/v1/reservation-slots")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{"
                                + "\"shopId\":20001,"
                                + "\"bizDate\":\"" + date + "\","
                                + "\"startTime\":\"18:00:00\","
                                + "\"endTime\":\"20:00:00\","
                                + "\"capacity\":12,"
                                + "\"confirmMode\":2,"
                                + "\"cancelBeforeMinutes\":120,"
                                + "\"enabled\":true"
                                + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.shopId").value(20001))
                .andExpect(jsonPath("$.data.capacity").value(12))
                .andExpect(jsonPath("$.data.enabled").value(true))
                .andReturn();
        long slotId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/b/v1/reservation-slots")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("shopId", "20001")
                        .param("dateFrom", date.toString())
                        .param("dateTo", date.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(org.hamcrest.Matchers.greaterThanOrEqualTo(1)));

        mockMvc.perform(put("/api/b/v1/reservation-slots/{id}", slotId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{"
                                + "\"shopId\":20001,"
                                + "\"bizDate\":\"" + date + "\","
                                + "\"startTime\":\"18:30:00\","
                                + "\"endTime\":\"20:30:00\","
                                + "\"capacity\":16,"
                                + "\"confirmMode\":1,"
                                + "\"cancelBeforeMinutes\":90,"
                                + "\"enabled\":true"
                                + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.capacity").value(16))
                .andExpect(jsonPath("$.data.confirmMode").value(1))
                .andExpect(jsonPath("$.data.startTime").value("18:30:00"));

        mockMvc.perform(put("/api/b/v1/reservation-slots/{id}/status", slotId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.enabled").value(false));
    }

    private String merchantToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"merchant_eu_sichuan@example.com\",\"password\":\"merchant123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
