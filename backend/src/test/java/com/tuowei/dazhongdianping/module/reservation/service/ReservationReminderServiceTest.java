package com.tuowei.dazhongdianping.module.reservation.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationReminderResult;
import java.time.LocalDateTime;
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
class ReservationReminderServiceTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private ReservationReminderService reminderService;

    @Test
    void shouldSendTwoHourAndThirtyMinuteRemindersWithoutDuplication() throws Exception {
        RegisteredUser user = registerUser();
        LocalDateTime twoHourReserve = LocalDateTime.now().plusMinutes(90).withSecond(0).withNano(0);
        LocalDateTime thirtyMinuteReserve = LocalDateTime.now().plusMinutes(20).withSecond(0).withNano(0);

        long twoHourId = insertConfirmedReservation(user.userId(), twoHourReserve, shortNo("2H"));
        long thirtyMinuteId = insertConfirmedReservation(user.userId(), thirtyMinuteReserve, shortNo("30"));

        ReservationReminderResult first = reminderService.dispatchDueReminders();
        assertEquals(1, first.twoHourSent());
        assertEquals(1, first.thirtyMinuteSent());

        Integer twoHourStatus = jdbc.queryForObject(
                "SELECT remind_status FROM reservation WHERE id=?",
                Integer.class,
                twoHourId
        );
        Integer thirtyMinuteStatus = jdbc.queryForObject(
                "SELECT remind_status FROM reservation WHERE id=?",
                Integer.class,
                thirtyMinuteId
        );
        assertEquals(1, twoHourStatus);
        assertEquals(2, thirtyMinuteStatus);

        Integer logCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM reservation_change_log WHERE reservation_id IN (?, ?) AND action_type=9",
                Integer.class,
                twoHourId,
                thirtyMinuteId
        );
        assertEquals(2, logCount);

        mockMvc.perform(get("/api/c/v1/notifications")
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].type").value("reservation.reminder"))
                .andExpect(jsonPath("$.data.list[*].linkUrl").value(org.hamcrest.Matchers.hasItems(
                        "/user/reservations/" + thirtyMinuteId + "?remind=30",
                        "/user/reservations/" + twoHourId + "?remind=120"
                )));

        mockMvc.perform(get("/api/c/v1/reservations/{id}", twoHourId)
                        .header("Authorization", bearer(user.accessToken()))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.timeline[0].actionType").value(9))
                .andExpect(jsonPath("$.data.timeline[0].actionText").value("到店提醒"))
                .andExpect(jsonPath("$.data.timeline[0].operatorText").value("系统"));

        ReservationReminderResult second = reminderService.dispatchDueReminders();
        assertEquals(0, second.twoHourSent());
        assertEquals(0, second.thirtyMinuteSent());
        assertTrue(second.scanned() >= 0);

        Integer notificationCount = jdbc.queryForObject(
                "SELECT COUNT(1) FROM user_notification WHERE user_id=? AND type='reservation.reminder'",
                Integer.class,
                user.userId()
        );
        assertEquals(2, notificationCount);
    }

    @Test
    void shouldResetRemindStatusAfterRescheduleAndAllowNewWindow() throws Exception {
        RegisteredUser user = registerUser();
        LocalDateTime original = LocalDateTime.now().plusMinutes(80).withSecond(0).withNano(0);
        long reservationId = insertConfirmedReservation(user.userId(), original, shortNo("RS"));

        ReservationReminderResult first = reminderService.dispatchDueReminders();
        assertEquals(1, first.twoHourSent());
        assertEquals(1, jdbc.queryForObject(
                "SELECT remind_status FROM reservation WHERE id=?",
                Integer.class,
                reservationId
        ));

        LocalDateTime next = LocalDateTime.now().plusMinutes(100).withSecond(0).withNano(0);
        jdbc.update(
                "UPDATE reservation SET reserve_time=?, remind_status=0, updated_at=CURRENT_TIMESTAMP WHERE id=?",
                next,
                reservationId
        );

        ReservationReminderResult second = reminderService.dispatchDueReminders();
        assertEquals(1, second.twoHourSent());
        assertEquals(1, jdbc.queryForObject(
                "SELECT remind_status FROM reservation WHERE id=?",
                Integer.class,
                reservationId
        ));
        assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM reservation_change_log WHERE reservation_id=? AND action_type=9",
                Integer.class,
                reservationId
        ));
    }

    private String shortNo(String prefix) {
        return ("R" + prefix + UUID.randomUUID().toString().replace("-", "")).substring(0, 20);
    }

    private long insertConfirmedReservation(long userId, LocalDateTime reserveTime, String reservationNo) {
        jdbc.update("""
                INSERT INTO reservation(
                    reservation_no, user_id, shop_id, slot_id, region, reserve_time, people_count,
                    contact_name, contact_phone, remark, status, remind_status, confirmed_at
                ) VALUES (?, ?, 10001, 0, 'CN', ?, 2, '提醒用户', '+8613800000000', '', 1, 0, CURRENT_TIMESTAMP)
                """, reservationNo, userId, reserveTime);
        return jdbc.queryForObject(
                "SELECT id FROM reservation WHERE reservation_no=?",
                Long.class,
                reservationNo
        );
    }

    private RegisteredUser registerUser() throws Exception {
        String account = "remind-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + account
                                + "\",\"deviceId\":\"remind-test\"}"))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + account
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk())
                .andReturn();
        long userId = objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/user/id").asLong();
        String accessToken = objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
        return new RegisteredUser(userId, accessToken);
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record RegisteredUser(long userId, String accessToken) {
    }
}
