package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyReminderResult;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GroupBuyReminderService {

    private static final Logger log = LoggerFactory.getLogger(GroupBuyReminderService.class);
    private static final int BATCH_SIZE = 200;
    private static final int WINDOW_MINUTES = 60;
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    private final MarketingCampaignMapper mapper;
    private final NotificationService notifications;

    public GroupBuyReminderService(MarketingCampaignMapper mapper, NotificationService notifications) {
        this.mapper = mapper;
        this.notifications = notifications;
    }

    @Transactional
    public GroupBuyReminderResult dispatchDueReminders() {
        LocalDateTime now = LocalDateTime.now();
        var due = mapper.selectDueGroupBuyReminders(now, now.plusMinutes(WINDOW_MINUTES), BATCH_SIZE);
        int sent = 0;
        int skipped = 0;
        for (var reminder : due) {
            if (mapper.markGroupBuyReminderSent(reminder.getMemberId()) != 1) {
                skipped++;
                continue;
            }
            String title = "拼团即将截止";
            String content = reminder.getCampaignTitle()
                    + " · " + reminder.getPaidCount() + "/" + reminder.getGroupSize() + " 人已付款"
                    + " · " + reminder.getExpireAt().format(FORMATTER) + " 截止";
            notifications.create(
                    reminder.getUserId(), reminder.getRegion(), "groupbuy.deadline",
                    title, content, "/marketing/groupbuy?teamId=" + reminder.getTeamId());
            sent++;
        }
        if (sent > 0) log.info("group-buy deadline reminders dispatched: scanned={}, sent={}, skipped={}", due.size(), sent, skipped);
        return new GroupBuyReminderResult(due.size(), sent, skipped);
    }
}
