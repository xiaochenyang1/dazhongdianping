package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
class MerchantFulfillmentControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldConfirmArriveRejectReservationAndVerifyCoupon() throws Exception {
        String user = userToken();
        String merchant = merchantToken();
        long reservationId = createReservation(user, true);

        mockMvc.perform(post("/api/b/v1/reservations/{id}/confirm", reservationId)
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        mockMvc.perform(post("/api/b/v1/reservations/{id}/arrive", reservationId)
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));

        long secondId = createReservation(user, false);
        mockMvc.perform(post("/api/b/v1/reservations/{id}/reject", secondId)
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"满桌\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(4));

        jdbc.update("INSERT INTO coupon(order_id,user_id,deal_id,shop_id,code,status,expire_at) "
                + "VALUES(999,9001,41001,20001,'VERIFYME001',1,'2026-12-31')");
        mockMvc.perform(post("/api/b/v1/coupons/VERIFYME001/verify")
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.statusText").value("已使用"))
                .andExpect(jsonPath("$.data.code").value("VERIFYME001"));
    }

    @Test
    void shouldReleaseCapacityAndRecordMerchantTimelineWhenMarkingNoShow() throws Exception {
        String user = userToken();
        String merchant = merchantToken();
        Integer before = jdbc.queryForObject(
                "SELECT reserved_count FROM reservation_slot WHERE id=51001",
                Integer.class
        );
        long reservationId = createReservation(user, false);

        mockMvc.perform(post("/api/b/v1/reservations/{id}/confirm", reservationId)
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/b/v1/reservations/{id}/no-show", reservationId)
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(5));

        Integer after = jdbc.queryForObject(
                "SELECT reserved_count FROM reservation_slot WHERE id=51001",
                Integer.class
        );
        Integer noShowLogs = jdbc.queryForObject(
                "SELECT COUNT(1) FROM reservation_change_log "
                        + "WHERE reservation_id=? AND action_type=8 AND operator_type=2 AND operator_id=12001",
                Integer.class,
                reservationId
        );
        assertEquals(before, after);
        assertEquals(1, noShowLogs);
    }

    @Test
    void shouldNotAllowMerchantToOperateAnotherMerchantsReservationOrCoupon() throws Exception {
        String merchant = merchantToken();
        String reservationNo = "CROSS" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        jdbc.update("INSERT INTO reservation(reservation_no,user_id,shop_id,slot_id,region,reserve_time,"
                        + "people_count,contact_name,contact_phone,remark,status) "
                        + "VALUES(?,9001,20002,0,'EU','2026-07-20 18:30:00',2,'Noah','+49301234567','',0)",
                reservationNo);
        Long reservationId = jdbc.queryForObject(
                "SELECT id FROM reservation WHERE reservation_no=?",
                Long.class,
                reservationNo
        );
        jdbc.update("INSERT INTO coupon(order_id,user_id,deal_id,shop_id,code,status,expire_at) "
                + "VALUES(998,9001,41001,20002,'CROSSSHOP001',1,'2026-12-31')");

        mockMvc.perform(post("/api/b/v1/reservations/{id}/confirm", reservationId)
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/b/v1/coupons/CROSSSHOP001/verify")
                        .header("Authorization", bearer(merchant))
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());

        assertEquals(0, jdbc.queryForObject(
                "SELECT status FROM reservation WHERE id=?",
                Integer.class,
                reservationId
        ));
        assertEquals(1, jdbc.queryForObject(
                "SELECT status FROM coupon WHERE code='CROSSSHOP001'",
                Integer.class
        ));
    }

    @Test
    void shouldEnforceStaffPermissionsAndRecordActualOperatorId() throws Exception {
        String ownerToken = merchantToken();
        String user = userToken();
        long confirmedReservation = createReservation(user, false);
        long pendingReservation = createReservation(user, false);
        mockMvc.perform(post("/api/b/v1/reservations/{id}/confirm", confirmedReservation)
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        String staffAccount = "fulfillment-" + UUID.randomUUID() + "@example.com";
        MvcResult created = mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Staff#123456",
                                  "name": "Verifier",
                                  "phone": "+33100000002",
                                  "email": "%s",
                                  "roleIds": [12],
                                  "shopScopeType": 2,
                                  "shopIds": [20001]
                                }
                                """.formatted(staffAccount, staffAccount)))
                .andExpect(status().isOk())
                .andReturn();
        long staffId = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();
        String staffToken = loginMerchant(staffAccount, "Staff#123456");

        mockMvc.perform(post("/api/b/v1/reservations/{id}/confirm", pendingReservation)
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/b/v1/reservations/{id}/arrive", confirmedReservation)
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        jdbc.update("INSERT INTO coupon(order_id,user_id,deal_id,shop_id,code,status,expire_at) "
                + "VALUES(997,9001,41001,20001,'STAFFVERIFY01',1,'2026-12-31')");
        mockMvc.perform(post("/api/b/v1/coupons/STAFFVERIFY01/verify")
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.verifyBy").value(staffId));

        assertEquals(staffId, jdbc.queryForObject(
                "SELECT operator_id FROM reservation_change_log WHERE reservation_id=? AND action_type=7",
                Long.class,
                confirmedReservation
        ));
    }

    private long createReservation(String userToken, boolean includeReserveTime) throws Exception {
        String reserveTime = includeReserveTime ? ",\"reserveTime\":\"2026-07-20 18:30:00\"" : "";
        MvcResult created = mockMvc.perform(post("/api/c/v1/reservations")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"shopId\":20001,\"slotId\":51001" + reserveTime
                                + ",\"peopleCount\":2,\"contactName\":\"Lina\","
                                + "\"contactPhone\":\"+33123456789\",\"remark\":\"\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(created.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private String merchantToken() throws Exception {
        return loginMerchant("merchant_eu_sichuan@example.com", "merchant123456");
    }

    private String loginMerchant(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\","
                                + "\"password\":\"" + password + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String userToken() throws Exception {
        String account = "merchant-flow-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\""
                                + account + "\",\"deviceId\":\"merchant-flow\"}"))
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
