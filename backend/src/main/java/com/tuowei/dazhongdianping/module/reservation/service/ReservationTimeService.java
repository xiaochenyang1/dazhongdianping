package com.tuowei.dazhongdianping.module.reservation.service;

import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class ReservationTimeService {
    private final Clock clock;

    public ReservationTimeService(Clock clock) {
        this.clock = clock;
    }

    public Instant now() {
        return clock.instant();
    }

    public LocalDate today(String timeZone) {
        return now().atZone(ZoneId.of(timeZone)).toLocalDate();
    }

    public Instant requireUnambiguous(LocalDateTime localTime, String timeZone) {
        List<ZoneOffset> offsets = ZoneId.of(timeZone).getRules().getValidOffsets(localTime);
        if (offsets.size() != 1) {
            throw new IllegalArgumentException("该当地时间处于夏令时切换，请选择其他时段");
        }
        return localTime.toInstant(offsets.get(0));
    }

    public void requireFuture(LocalDateTime localTime, String timeZone) {
        if (!requireUnambiguous(localTime, timeZone).isAfter(now())) {
            throw new IllegalArgumentException("预订时间必须晚于门店当前时间");
        }
    }

    public Instant reservationInstant(ReservationRow reservation) {
        // New bookings reject repeated/nonexistent times. Legacy repeated wall times
        // consistently use the earlier offset, matching java.time's standard rule.
        return reservation.getReserveTime().atZone(ZoneId.of(reservation.getTimeZone())).toInstant();
    }

    public boolean canCancel(ReservationRow reservation) {
        if (!isPending(reservation)) return false;
        int minutes = reservation.getCancelBeforeMinutes() == null ? 120 : reservation.getCancelBeforeMinutes();
        return !now().isAfter(reservationInstant(reservation).minusSeconds(minutes * 60L));
    }

    public boolean canReschedule(ReservationRow reservation) {
        return isPending(reservation)
                && Boolean.TRUE.equals(reservation.getBookingEnabled())
                && reservationInstant(reservation).isAfter(now());
    }

    private boolean isPending(ReservationRow reservation) {
        return Integer.valueOf(0).equals(reservation.getStatus()) || Integer.valueOf(1).equals(reservation.getStatus());
    }
}
