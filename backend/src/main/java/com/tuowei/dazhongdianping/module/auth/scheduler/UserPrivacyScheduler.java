package com.tuowei.dazhongdianping.module.auth.scheduler;

import com.tuowei.dazhongdianping.module.auth.service.UserPrivacyService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class UserPrivacyScheduler {
    private static final Logger log = LoggerFactory.getLogger(UserPrivacyScheduler.class);
    private final UserPrivacyService privacyService;

    public UserPrivacyScheduler(UserPrivacyService privacyService) { this.privacyService = privacyService; }

    @Scheduled(fixedDelayString = "${app.privacy.delete-fixed-delay-ms:60000}",
            initialDelayString = "${app.privacy.delete-initial-delay-ms:60000}")
    public void processDueTasks() {
        for (Long userId : privacyService.dueDeleteUserIds()) {
            try {
                privacyService.processDueDeleteTasksForUser(userId);
            } catch (RuntimeException exception) {
                log.warn("Privacy deletion will retry for account {} ({})", userId, exception.getClass().getSimpleName());
            }
        }
        privacyService.cleanupExpiredExportArchives();
    }
}
