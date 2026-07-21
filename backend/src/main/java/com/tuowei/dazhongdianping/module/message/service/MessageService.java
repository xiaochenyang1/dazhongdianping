package com.tuowei.dazhongdianping.module.message.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.message.mapper.MessageMapper;
import com.tuowei.dazhongdianping.module.message.model.BlockedUserRow;
import com.tuowei.dazhongdianping.module.message.model.ConversationRow;
import com.tuowei.dazhongdianping.module.message.model.MessageRow;
import com.tuowei.dazhongdianping.module.message.model.request.ReportMessageRequest;
import com.tuowei.dazhongdianping.module.message.model.request.SendMessageRequest;
import com.tuowei.dazhongdianping.module.message.model.response.BlockStatusResponse;
import com.tuowei.dazhongdianping.module.message.model.response.BlockedUserResponse;
import com.tuowei.dazhongdianping.module.message.model.response.ConversationResponse;
import com.tuowei.dazhongdianping.module.message.model.response.MessageReportResponse;
import com.tuowei.dazhongdianping.module.message.model.response.MessageResponse;
import com.tuowei.dazhongdianping.module.message.model.response.ReadMessagesResponse;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.notification.websocket.NotificationSessionRegistry;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
public class MessageService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final MessageMapper mapper;
    private final NotificationSessionRegistry sessions;
    private final NotificationService notifications;
    public MessageService(MessageMapper mapper, NotificationSessionRegistry sessions, NotificationService notifications) {
        this.mapper = mapper; this.sessions = sessions; this.notifications = notifications;
    }

    @Transactional
    public MessageResponse send(SendMessageRequest request) {
        long senderId = currentUserId();
        long receiverId = request.toUserId();
        if (senderId == receiverId) throw new IllegalArgumentException("不能给自己发送私信");
        requireAvailableUser(receiverId);
        if (mapper.countBlockEitherDirection(senderId, receiverId) > 0) throw new ConflictException("双方存在拉黑关系，无法发送私信");
        long userA = Math.min(senderId, receiverId);
        long userB = Math.max(senderId, receiverId);
        Long conversationId = mapper.findConversation(userA, userB);
        if (conversationId == null) {
            try { mapper.insertConversation(userA, userB); } catch (DuplicateKeyException ignored) { }
            conversationId = mapper.findConversation(userA, userB);
        }
        MessageRow row = new MessageRow();
        row.setConversationId(conversationId); row.setFromUserId(senderId); row.setToUserId(receiverId);
        row.setContent(request.content().trim());
        mapper.insertMessage(row);
        mapper.updateConversation(conversationId, row.getId(), preview(row.getContent()));
        MessageResponse response = toMessage(row);
        notifications.create(receiverId, senderId, "GLOBAL", "message.direct", "收到私信",
                mapper.selectUserName(senderId) + "：" + preview(row.getContent()),
                "/messages/conversations/" + conversationId);
        Runnable notifyReceiver = () -> sessions.sendAllRegions(receiverId,
                Map.of("type", "message.new", "data", response));
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCommit() { notifyReceiver.run(); }
            });
        } else notifyReceiver.run();
        return response;
    }

    public PageResult<ConversationResponse> conversations(Integer page, Integer pageSize) {
        long userId = currentUserId();
        PageWindow window = pageWindow(page, pageSize);
        long total = mapper.countConversations(userId);
        List<ConversationResponse> list = mapper.listConversations(userId, window.size(), window.offset()).stream()
                .map(this::toConversation).toList();
        return new PageResult<>(list, total, window.page(), window.size(), window.offset() + list.size() < total);
    }

    public PageResult<MessageResponse> messages(Long conversationId, Integer page, Integer pageSize) {
        requireConversationMember(conversationId);
        PageWindow window = pageWindow(page, pageSize);
        long total = mapper.countMessages(conversationId);
        List<MessageResponse> list = mapper.listMessages(conversationId, window.size(), window.offset()).stream()
                .map(this::toMessage).toList();
        return new PageResult<>(list, total, window.page(), window.size(), window.offset() + list.size() < total);
    }

    @Transactional
    public ReadMessagesResponse markRead(Long conversationId) {
        long userId = currentUserId();
        requireConversationMember(conversationId);
        return new ReadMessagesResponse(conversationId, mapper.markRead(conversationId, userId));
    }

    @Transactional
    public BlockStatusResponse block(Long blockedUserId) {
        long userId = currentUserId();
        if (userId == blockedUserId) throw new IllegalArgumentException("不能拉黑自己");
        requireAvailableUser(blockedUserId);
        try { mapper.insertBlock(userId, blockedUserId); } catch (DuplicateKeyException ignored) { }
        return new BlockStatusResponse(blockedUserId, true);
    }

    @Transactional
    public BlockStatusResponse unblock(Long blockedUserId) {
        long userId = currentUserId();
        mapper.deleteBlock(userId, blockedUserId);
        return new BlockStatusResponse(blockedUserId, false);
    }

    public PageResult<BlockedUserResponse> blocks(Integer page, Integer pageSize) {
        long userId = currentUserId();
        PageWindow window = pageWindow(page, pageSize);
        long total = mapper.countBlocks(userId);
        List<BlockedUserResponse> list = mapper.listBlocks(userId, window.size(), window.offset()).stream()
                .map(this::toBlockedUser).toList();
        return new PageResult<>(list, total, window.page(), window.size(), window.offset() + list.size() < total);
    }

    @Transactional
    public MessageReportResponse report(ReportMessageRequest request) {
        long userId = currentUserId();
        if (mapper.countReportableTarget(userId, request.targetType(), request.targetId()) == 0) {
            throw new NotFoundException("举报目标不存在或无权访问");
        }
        if (mapper.countReport(userId, request.targetType(), request.targetId()) > 0) {
            throw new ConflictException("请勿重复举报");
        }
        mapper.insertReport(userId, request.targetType(), request.targetId(), request.reason().trim());
        return new MessageReportResponse(mapper.lastInsertedId(), request.targetType(), request.targetId(), "pending");
    }

    private void requireAvailableUser(Long userId) {
        if (mapper.countAvailableUser(userId) == 0) throw new NotFoundException("用户不存在");
    }
    private void requireConversationMember(Long conversationId) {
        if (mapper.countConversationMember(conversationId, currentUserId()) == 0) throw new NotFoundException("会话不存在");
    }
    private long currentUserId() {
        UserSession session = UserSessionContext.get();
        if (session == null) throw new UnauthorizedException("用户登录状态不存在");
        return session.userId();
    }
    private PageWindow pageWindow(Integer page, Integer pageSize) {
        int currentPage = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 20 : Math.min(50, Math.max(1, pageSize));
        return new PageWindow(currentPage, size, (currentPage - 1) * size);
    }
    private MessageResponse toMessage(MessageRow row) {
        return new MessageResponse(row.getId(), row.getConversationId(), row.getFromUserId(), row.getToUserId(),
                row.getContent(), row.isRead(), format(row.getReadAt()), format(row.getCreatedAt()));
    }
    private ConversationResponse toConversation(ConversationRow row) {
        return new ConversationResponse(row.getId(), row.getPeerUserId(), row.getPeerNickname(), row.getPeerAvatar(),
                row.getLastMessagePreview(), format(row.getLastMessageAt()), row.getUnreadCount());
    }
    private BlockedUserResponse toBlockedUser(BlockedUserRow row) {
        return new BlockedUserResponse(row.getId(), row.getNickname(), row.getAvatar(), format(row.getBlockedAt()));
    }
    private String preview(String content) { return content.length() <= 200 ? content : content.substring(0, 200); }
    private String format(LocalDateTime value) { return value == null ? "" : value.format(FORMATTER); }
    private record PageWindow(int page, int size, int offset) {}
}
