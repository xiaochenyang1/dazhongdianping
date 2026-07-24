package com.tuowei.dazhongdianping.module.reservation.service;

import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.reservation.mapper.ReservationMapper;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationLogRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationReminderResult;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReservationReminderService {

    private static final Logger log = LoggerFactory.getLogger(ReservationReminderService.class);
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final String NOTIFICATION_TYPE = "reservation.reminder";
    private static final int ACTION_REMIND = 9;
    private static final int OPERATOR_SYSTEM = 3;
    private static final int BATCH_SIZE = 100;
    private static final int TWO_HOUR_MINUTES = 120;
    private static final int THIRTY_MINUTE_MINUTES = 30;
    private static final int FLAG_TWO_HOUR = 1;
    private static final int FLAG_THIRTY_MINUTE = 2;

    private final ReservationMapper reservationMapper;
    private final NotificationService notificationService;

    public ReservationReminderService(
            ReservationMapper reservationMapper,
            NotificationService notificationService
    ) {
        this.reservationMapper = reservationMapper;
        this.notificationService = notificationService;
    }

    @Transactional
    public ReservationReminderResult dispatchDueReminders() {
        LocalDateTime now = LocalDateTime.now().withNano(0);
        LocalDateTime windowEnd = now.plusMinutes(TWO_HOUR_MINUTES);
        List<ReservationRow> due = reservationMapper.selectDueReminders(now, windowEnd, BATCH_SIZE);

        int twoHourSent = 0;
        int thirtyMinuteSent = 0;
        int skipped = 0;

        for (ReservationRow reservation : due) {
            int currentStatus = reservation.getRemindStatus() == null ? 0 : reservation.getRemindStatus();
            long minutesUntil = Duration.between(now, reservation.getReserveTime()).toMinutes();

            if (minutesUntil <= THIRTY_MINUTE_MINUTES && (currentStatus & FLAG_THIRTY_MINUTE) == 0) {
                if (sendReminder(reservation, currentStatus, currentStatus | FLAG_THIRTY_MINUTE, THIRTY_MINUTE_MINUTES)) {
                    thirtyMinuteSent++;
                    currentStatus = currentStatus | FLAG_THIRTY_MINUTE;
                } else {
                    skipped++;
                    continue;
                }
            }

            if (minutesUntil <= TWO_HOUR_MINUTES
                    && minutesUntil > THIRTY_MINUTE_MINUTES
                    && (currentStatus & FLAG_TWO_HOUR) == 0) {
                if (sendReminder(reservation, currentStatus, currentStatus | FLAG_TWO_HOUR, TWO_HOUR_MINUTES)) {
                    twoHourSent++;
                } else {
                    skipped++;
                }
            }
        }

        if (twoHourSent > 0 || thirtyMinuteSent > 0) {
            log.info(
                    "reservation reminders dispatched: scanned={}, twoHourSent={}, thirtyMinuteSent={}, skipped={}",
                    due.size(),
                    twoHourSent,
                    thirtyMinuteSent,
                    skipped
            );
        }
        return new ReservationReminderResult(due.size(), twoHourSent, thirtyMinuteSent, skipped);
    }

    private boolean sendReminder(
            ReservationRow reservation,
            int expectedStatus,
            int nextStatus,
            int windowMinutes
    ) {
        if (reservationMapper.markRemindStatus(reservation.getId(), expectedStatus, nextStatus) != 1) {
            return false;
        }

        String reserveTimeText = reservation.getReserveTime().format(TIME_FORMATTER);
        String shopName = reservation.getShopName() == null ? "门店" : reservation.getShopName();
        String title = windowMinutes == THIRTY_MINUTE_MINUTES
                ? "预订即将开始（30 分钟）"
                : "预订提醒（2 小时）";
        String content = shopName + " · " + reserveTimeText + " · " + reservation.getPeopleCount() + " 人";
        // Include window marker so 2h / 30m reminders stay distinct in the unread aggregate.
        String linkUrl = "/user/reservations/" + reservation.getId() + "?remind=" + windowMinutes;

        notificationService.create(
                reservation.getUserId(),
                reservation.getRegion(),
                NOTIFICATION_TYPE,
                title,
                content,
                linkUrl
        );

        ReservationLogRow logRow = new ReservationLogRow();
        logRow.setReservationId(reservation.getId());
        logRow.setActionType(ACTION_REMIND);
        logRow.setOperatorType(OPERATOR_SYSTEM);
        logRow.setOperatorId(0L);
        logRow.setFromStatus(reservation.getStatus());
        logRow.setToStatus(reservation.getStatus());
        logRow.setOldReserveTime(reservation.getReserveTime());
        logRow.setNewReserveTime(reservation.getReserveTime());
        logRow.setRemark(windowMinutes == THIRTY_MINUTE_MINUTES ? "系统发送到店前 30 分钟提醒" : "系统发送到店前 2 小时提醒");
        reservationMapper.insertLog(logRow);
        return true;
    }
}
