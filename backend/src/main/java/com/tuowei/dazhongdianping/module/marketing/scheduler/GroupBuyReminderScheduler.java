package com.tuowei.dazhongdianping.module.marketing.scheduler;

import com.tuowei.dazhongdianping.module.marketing.service.GroupBuyReminderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class GroupBuyReminderScheduler {
    private static final Logger log = LoggerFactory.getLogger(GroupBuyReminderScheduler.class);
    private final GroupBuyReminderService reminders;

    public GroupBuyReminderScheduler(GroupBuyReminderService reminders) {
        this.reminders = reminders;
    }

    @Scheduled(cron = "17 * * * * *")
    public void dispatchDueReminders() {
        try {
            reminders.dispatchDueReminders();
        } catch (RuntimeException failure) {
            log.error("group-buy reminder dispatch failed", failure);
        }
    }
}
