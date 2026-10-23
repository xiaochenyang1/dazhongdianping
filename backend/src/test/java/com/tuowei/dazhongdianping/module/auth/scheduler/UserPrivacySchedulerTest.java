package com.tuowei.dazhongdianping.module.auth.scheduler;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.module.auth.service.UserPrivacyService;
import java.util.List;
import org.junit.jupiter.api.Test;

class UserPrivacySchedulerTest {
    @Test
    void oneFailedDeletionDoesNotPreventOtherDueAccountsOrArchiveCleanup() {
        UserPrivacyService service = mock(UserPrivacyService.class);
        when(service.dueDeleteUserIds()).thenReturn(List.of(91L, 92L));
        doThrow(new IllegalStateException("synthetic transient failure")).when(service).processDueDeleteTasksForUser(91L);
        new UserPrivacyScheduler(service).processDueTasks();
        var order = inOrder(service);
        order.verify(service).processDueDeleteTasksForUser(91L);
        order.verify(service).processDueDeleteTasksForUser(92L);
        order.verify(service).cleanupExpiredExportArchives();
    }
}
