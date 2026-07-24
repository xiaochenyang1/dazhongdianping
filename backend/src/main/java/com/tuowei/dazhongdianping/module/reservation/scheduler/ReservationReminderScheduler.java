package com.tuowei.dazhongdianping.module.reservation.scheduler;

import com.tuowei.dazhongdianping.module.reservation.service.ReservationReminderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class ReservationReminderScheduler {

    private static final Logger log = LoggerFactory.getLogger(ReservationReminderScheduler.class);

    private final ReservationReminderService reminderService;

    public ReservationReminderScheduler(ReservationReminderService reminderService) {
        this.reminderService = reminderService;
    }

    @Scheduled(cron = "41 * * * * *")
    public void dispatchDueReminders() {
        try {
            reminderService.dispatchDueReminders();
        } catch (RuntimeException exception) {
            log.error("reservation reminder dispatch failed", exception);
        }
    }
}
