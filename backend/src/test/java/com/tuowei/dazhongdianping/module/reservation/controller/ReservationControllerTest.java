package com.tuowei.dazhongdianping.module.reservation.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
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
class ReservationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void shouldReserveRescheduleCancelAndTrackCapacity() throws Exception {
        LocalDate firstDate = LocalDate.now().plusDays(1);
        LocalDate secondDate = firstDate.plusDays(1);
        String firstReserveTime = firstDate + " 18:00:00";
        String secondReserveTime = secondDate + " 19:00:00";
        jdbc.update("UPDATE reservation_slot SET biz_date=? WHERE id=?",
                java.sql.Date.valueOf(firstDate), 50001L);
        jdbc.update("UPDATE reservation_slot SET biz_date=? WHERE id=?",
                java.sql.Date.valueOf(secondDate), 50002L);

        String token = register();

        mockMvc.perform(get("/api/c/v1/shops/10001/reservation-slots")
                        .header("X-Region", "CN")
                        .param("date", firstDate.toString())
                        .param("peopleCount", "4"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].remainingCount").value(10))
                .andExpect(jsonPath("$.data.list[0].confirmModeText").value("自动确认"));

        MvcResult created = mockMvc.perform(post("/api/c/v1/reservations")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":10001,\"slotId\":50001,\"reserveTime\":\"" + firstReserveTime
                                + "\",\"peopleCount\":4,\"contactName\":\"张三\",\"contactPhone\":\"+8613812345678\",\"remark\":\"靠窗\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andReturn();
        long id = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(post("/api/c/v1/reservations/{id}/reschedule", id)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"slotId\":50002,\"reserveTime\":\"" + secondReserveTime
                                + "\",\"reason\":\"改到明晚\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(jsonPath("$.data.rescheduleCount").value(1));

        mockMvc.perform(get("/api/c/v1/reservations/{id}", id)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.timeline.length()").value(2))
                .andExpect(jsonPath("$.data.timeline[0].actionText").value("用户改期"));

        mockMvc.perform(post("/api/c/v1/reservations/{id}/cancel", id)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(3));

        mockMvc.perform(get("/api/c/v1/shops/10001/reservation-slots")
                        .header("X-Region", "CN")
                        .param("date", secondDate.toString())
                        .param("peopleCount", "4"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].remainingCount").value(10));
    }

    private String register() throws Exception {
        String account = "reservation-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"reservation-test\"}"))
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
