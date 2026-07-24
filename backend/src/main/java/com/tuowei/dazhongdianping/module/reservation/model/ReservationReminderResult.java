package com.tuowei.dazhongdianping.module.reservation.model;

public record ReservationReminderResult(
        int scanned,
        int twoHourSent,
        int thirtyMinuteSent,
        int skipped
) {
}
