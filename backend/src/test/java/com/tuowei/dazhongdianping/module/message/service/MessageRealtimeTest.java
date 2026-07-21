package com.tuowei.dazhongdianping.module.message.service;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.message.mapper.MessageMapper;
import com.tuowei.dazhongdianping.module.message.model.MessageRow;
import com.tuowei.dazhongdianping.module.message.model.request.SendMessageRequest;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.notification.websocket.NotificationSessionRegistry;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

class MessageRealtimeTest {
    @AfterEach void cleanup() {
        UserSessionContext.clear();
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void shouldSendMessageNewToAllReceiverRegionsOnlyAfterCommit() {
        MessageMapper mapper = Mockito.mock(MessageMapper.class);
        NotificationSessionRegistry sessions = Mockito.mock(NotificationSessionRegistry.class);
        NotificationService notifications = Mockito.mock(NotificationService.class);
        when(mapper.countAvailableUser(22L)).thenReturn(1);
        when(mapper.countBlockEitherDirection(11L, 22L)).thenReturn(0);
        when(mapper.findConversation(11L, 22L)).thenReturn(33L);
        when(mapper.selectUserName(11L)).thenReturn("事务发送者");
        when(mapper.insertMessage(any(MessageRow.class))).thenAnswer(invocation -> {
            MessageRow row = invocation.getArgument(0);
            row.setId(44L);
            return 1;
        });
        UserSessionContext.set(new UserSession(11L, 99L));
        TransactionSynchronizationManager.initSynchronization();

        new MessageService(mapper, sessions, notifications).send(new SendMessageRequest(22L, "事务消息"));

        verify(sessions, never()).sendAllRegions(eq(22L), any());
        for (TransactionSynchronization synchronization : TransactionSynchronizationManager.getSynchronizations()) {
            synchronization.afterCommit();
        }
        verify(sessions).sendAllRegions(eq(22L), any());
    }
}
