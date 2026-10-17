package com.tuowei.dazhongdianping.module.reservation.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.reservation.service.ReservationReminderService;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class ReservationLaunchBoundaryTest {
    private static final Instant SPRING_NOW = Instant.parse("2026-03-29T00:30:00Z");
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired ReservationReminderService reminders;
    @MockBean Clock clock;
    private String userToken;
    private long userId;

    @BeforeEach
    void setup() throws Exception {
        when(clock.instant()).thenReturn(SPRING_NOW);
        String account = "launch-" + UUID.randomUUID() + "@example.com";
        request("/api/c/v1/auth/send-code", "", Map.of(
                "scene", "register", "type", "email", "account", account, "deviceId", "launch-boundary"))
                .andExpect(status().isOk());
        JsonNode auth = data(request("/api/c/v1/auth/register", "", Map.of(
                "type", "email", "account", account, "code", "123456", "password", "Passw0rd!")));
        userToken = auth.path("accessToken").asText();
        userId = auth.at("/user/id").asLong();
    }

    @Test
    void disabledBerlinCannotBeBookedWithOrWithoutSlot() throws Exception {
        mvc.perform(get("/api/c/v1/cities").header("X-Region", "EU"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].timeZone").value("Europe/Paris"));
        jdbc.update("""
                INSERT INTO reservation_slot(id,shop_id,region,biz_date,start_time,end_time,capacity,
                  reserved_count,confirm_mode,cancel_before_minutes,enabled)
                VALUES(51999,20002,'EU','2026-03-30','18:00:00','20:00:00',8,0,1,120,TRUE)
                """);
        mvc.perform(get("/api/c/v1/shops/20002/reservation-slots").header("X-Region", "EU").param("peopleCount", "2"))
                .andExpect(status().isNotFound());
        create(20002, null, "2026-03-30 18:00:00").andExpect(status().isNotFound());
        create(20002, 51999L, null).andExpect(status().isNotFound());
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM reservation WHERE user_id=?", Integer.class, userId)).isZero();
        assertThat(jdbc.queryForObject("SELECT reserved_count FROM reservation_slot WHERE id=51999", Integer.class)).isZero();
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "UPDATE shop SET status=0 WHERE id=20001",
            "UPDATE shop SET is_deleted=TRUE WHERE id=20001",
            "UPDATE city SET status=0 WHERE id=101",
            "UPDATE area SET status=0 WHERE id=1011",
            "UPDATE category SET status=0 WHERE id=201"
    })
    void disabledGeographyPreventsEveryCreationPath(String disable) throws Exception {
        jdbc.update(disable);
        create(20001, null, "2026-03-30 18:00:00").andExpect(status().isNotFound());
        create(20001, 51001L, null).andExpect(status().isNotFound());
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM reservation WHERE user_id=?", Integer.class, userId)).isZero();
    }

    @Test
    void missingSlotQueryParameterIsAClientError() throws Exception {
        mvc.perform(get("/api/c/v1/shops/20001/reservation-slots").header("X-Region", "EU"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void cannotBookAcrossRegions() throws Exception {
        create(10001, null, "2026-03-30 18:00:00").andExpect(status().isNotFound());
        create(10001, 50001L, null).andExpect(status().isNotFound());
    }

    @ParameterizedTest
    @ValueSource(strings = {"2026-03-29 02:30:00", "2026-10-25 02:30:00", "2026-03-29 01:00:00"})
    void rejectsNonexistentRepeatedAndPastLocalTimes(String localTime) throws Exception {
        create(20001, null, localTime).andExpect(status().isBadRequest());
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM reservation WHERE user_id=?", Integer.class, userId)).isZero();
    }

    @Test
    void snapshotsShopZoneAndReturnsUnambiguousInstant() throws Exception {
        JsonNode created = data(create(20001, null, "2026-03-29 03:30:00")
                .andExpect(jsonPath("$.data.timeZone").value("Europe/Paris"))
                .andExpect(jsonPath("$.data.reserveAt").value("2026-03-29T01:30:00Z")));
        jdbc.update("UPDATE city SET time_zone='Europe/London' WHERE id=101");
        detail(created.path("id").asLong())
                .andExpect(jsonPath("$.data.timeZone").value("Europe/Paris"))
                .andExpect(jsonPath("$.data.reserveAt").value("2026-03-29T01:30:00Z"));
    }

    @Test
    void defaultsCalendarToShopTomorrowAndMarksDstGapUnavailable() throws Exception {
        when(clock.instant()).thenReturn(Instant.parse("2026-03-28T23:30:00Z"));
        mvc.perform(get("/api/c/v1/shops/20001/reservation-slots").header("X-Region", "EU").param("peopleCount", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.today").value("2026-03-29"))
                .andExpect(jsonPath("$.data.date").value("2026-03-30"));
        jdbc.update("UPDATE reservation_slot SET biz_date='2026-03-29',start_time='02:30:00' WHERE id=51001");
        mvc.perform(get("/api/c/v1/shops/20001/reservation-slots").header("X-Region", "EU").param("peopleCount", "2").param("date", "2026-03-29"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.list[0].available").value(false));
        create(20001, 51001L, null).andExpect(status().isBadRequest());
    }

    @ParameterizedTest
    @ValueSource(ints = {0, 1})
    void cancellationUsesTwoRealHoursAcrossSpringDst(int secondsAfterCutoff) throws Exception {
        long id = data(create(20001, null, "2026-03-29 04:30:00")).path("id").asLong();
        when(clock.instant()).thenReturn(SPRING_NOW.plusSeconds(secondsAfterCutoff));
        detail(id).andExpect(jsonPath("$.data.canCancel").value(secondsAfterCutoff == 0));
        request("/api/c/v1/reservations/" + id + "/cancel", userToken, Map.of())
                .andExpect(secondsAfterCutoff == 0 ? status().isOk() : status().isBadRequest());
    }

    @Test
    void disabledCityKeepsHistoryAndCancellationButBlocksConfirmationAndRescheduling() throws Exception {
        long id = data(create(20001, null, "2026-03-30 18:00:00")).path("id").asLong();
        String merchant = merchantToken();
        jdbc.update("UPDATE city SET status=0 WHERE id=101");
        detail(id).andExpect(jsonPath("$.data.canCancel").value(true))
                .andExpect(jsonPath("$.data.canReschedule").value(false));
        request("/api/c/v1/reservations/" + id + "/reschedule", userToken,
                Map.of("reserveTime", "2026-03-31 18:00:00", "reason", "change"))
                .andExpect(status().isNotFound());
        request("/api/b/v1/reservations/" + id + "/confirm", merchant, Map.of()).andExpect(status().isNotFound());
        request("/api/b/v1/reservations/" + id + "/reschedule", merchant,
                Map.of("slotId", 51001, "reason", "change")).andExpect(status().isNotFound());
        mvc.perform(get("/api/b/v1/reservations/" + id).header("X-Region", "EU")
                        .header("Authorization", "Bearer " + merchant))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.canConfirm").value(false))
                .andExpect(jsonPath("$.data.canReschedule").value(false));
        request("/api/c/v1/reservations/" + id + "/cancel", userToken, Map.of()).andExpect(status().isOk());
    }

    @Test
    void disabledCityBlocksSlotCreationAndEnablingButAllowsDisablingAndRejecting() throws Exception {
        long id = data(create(20001, null, "2026-03-30 18:00:00")).path("id").asLong();
        String merchant = merchantToken();
        jdbc.update("UPDATE city SET status=0 WHERE id=101");
        request("/api/b/v1/reservation-slots", merchant, Map.of("shopId", 20001,
                "bizDate", "2026-03-30", "startTime", "18:00:00", "endTime", "20:00:00",
                "capacity", 8, "confirmMode", 1, "cancelBeforeMinutes", 120, "enabled", true))
                .andExpect(status().isNotFound());
        for (boolean enabled : new boolean[]{false, true}) {
            mvc.perform(put("/api/b/v1/reservation-slots/51001/status").header("X-Region", "EU")
                            .header("Authorization", "Bearer " + merchant).contentType(MediaType.APPLICATION_JSON)
                            .content(json.writeValueAsString(Map.of("enabled", enabled))))
                    .andExpect(enabled ? status().isNotFound() : status().isOk());
        }
        request("/api/b/v1/reservations/" + id + "/reject", merchant, Map.of("reason", "city unavailable"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value(4));
    }

    @ParameterizedTest
    @ValueSource(strings = {"2026-03-29", "2026-10-25"})
    void remindersFollowRealElapsedTimeAcrossBothDstTransitionsAndDisabledCities(String day) {
        when(clock.instant()).thenReturn(Instant.parse(day + "T00:30:00Z"));
        String localTime = day.equals("2026-03-29") ? "04:15:00" : "03:15:00";
        for (long shopId : new long[]{20001, 20002}) {
            jdbc.update("""
                    INSERT INTO reservation(reservation_no,user_id,shop_id,slot_id,region,reserve_time,time_zone,
                      people_count,contact_name,contact_phone,remark,status,remind_status)
                    VALUES(?,?,?,0,'EU',?,?,2,'Reminder','+33123456789','',1,0)
                    """, "DST" + shopId, userId, shopId, day + " " + localTime,
                    shopId == 20001 ? "Europe/Paris" : "Europe/Berlin");
        }
        assertThat(reminders.dispatchDueReminders().twoHourSent()).isEqualTo(2);
        assertThat(reminders.dispatchDueReminders().twoHourSent()).isZero();
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM user_notification WHERE user_id=? AND type='reservation.reminder'",
                Integer.class, userId)).isEqualTo(2);
    }

    private ResultActions create(long shopId, Long slotId, String reserveTime) throws Exception {
        var body = new java.util.LinkedHashMap<String, Object>(Map.of("shopId", shopId, "peopleCount", 2,
                "contactName", "Paris", "contactPhone", "+33123456789"));
        if (slotId != null) body.put("slotId", slotId);
        if (reserveTime != null) body.put("reserveTime", reserveTime);
        return request("/api/c/v1/reservations", userToken, body);
    }

    private ResultActions detail(long id) throws Exception {
        return mvc.perform(get("/api/c/v1/reservations/" + id).header("X-Region", "EU")
                .header("Authorization", "Bearer " + userToken)).andExpect(status().isOk());
    }

    private String merchantToken() throws Exception {
        return data(request("/api/b/v1/auth/login", "", Map.of("account", "merchant_eu_sichuan@example.com",
                "password", "merchant123456"))).path("accessToken").asText();
    }

    private ResultActions request(String path, String token, Map<String, ?> body) throws Exception {
        return mvc.perform(post(path).header("X-Region", "EU").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(body)));
    }

    private JsonNode data(ResultActions result) throws Exception {
        return json.readTree(result.andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).path("data");
    }
}
