package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
class MerchantReservationWorkbenchControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldListFilteredReservationsAndReturnDetailTimeline() throws Exception {
        String userToken = userToken();
        long reservationId = createReservation(userToken);
        String merchantToken = merchantToken();

        mockMvc.perform(get("/api/b/v1/reservations")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .param("shopId", "20001")
                        .param("status", "0")
                        .param("dateFrom", "2026-07-20")
                        .param("dateTo", "2026-07-20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(reservationId))
                .andExpect(jsonPath("$.data.list[0].shop.id").value(20001))
                .andExpect(jsonPath("$.data.list[0].status").value(0));

        mockMvc.perform(get("/api/b/v1/reservations/{id}", reservationId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(reservationId))
                .andExpect(jsonPath("$.data.contactName").value("Lina"))
                .andExpect(jsonPath("$.data.timeline[0].actionType").value(1));
    }

    @Test
    void shouldRescheduleReservationAndExchangeSlotCapacity() throws Exception {
        jdbc.update("INSERT INTO reservation_slot(id,shop_id,region,biz_date,start_time,end_time,capacity,reserved_count,confirm_mode,cancel_before_minutes,enabled) "
                + "VALUES(51002,20001,'EU','2026-07-21','19:30:00','21:00:00',8,0,1,120,TRUE)");
        long reservationId = createReservation(userToken());
        Integer oldBefore = jdbc.queryForObject(
                "SELECT reserved_count FROM reservation_slot WHERE id=51001", Integer.class);
        Integer nextBefore = jdbc.queryForObject(
                "SELECT reserved_count FROM reservation_slot WHERE id=51002", Integer.class);

        mockMvc.perform(post("/api/b/v1/reservations/{id}/reschedule", reservationId)
                        .header("Authorization", bearer(merchantToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "slotId": 51002,
                                  "reserveTime": "2026-07-21 19:30:00",
                                  "reason": "Move to Tuesday evening"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.slotId").value(51002))
                .andExpect(jsonPath("$.data.status").value(1));

        assertEquals(
                oldBefore - 2,
                jdbc.queryForObject("SELECT reserved_count FROM reservation_slot WHERE id=51001", Integer.class)
        );
        assertEquals(
                nextBefore + 2,
                jdbc.queryForObject("SELECT reserved_count FROM reservation_slot WHERE id=51002", Integer.class)
        );
        mockMvc.perform(get("/api/b/v1/reservations/{id}", reservationId)
                        .header("Authorization", bearer(merchantToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.timeline[0].actionType").value(6));
    }

    private long createReservation(String token) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/c/v1/reservations")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "shopId": 20001,
                                  "slotId": 51001,
                                  "peopleCount": 2,
                                  "contactName": "Lina",
                                  "contactPhone": "+33123456789",
                                  "remark": "Window seat"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private String merchantToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"merchant_eu_sichuan@example.com\",\"password\":\"merchant123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String userToken() throws Exception {
        String account = "merchant-reservation-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\""
                                + account + "\",\"deviceId\":\"merchant-reservation\"}"))
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
