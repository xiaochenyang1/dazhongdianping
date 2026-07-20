package com.tuowei.dazhongdianping.module.notification.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.notification.mapper.NotificationMapper;
import com.tuowei.dazhongdianping.module.notification.model.NotificationRow;
import com.tuowei.dazhongdianping.module.notification.websocket.NotificationSessionRegistry;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
public class NotificationService {
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private final NotificationMapper mapper;
    private final NotificationSessionRegistry sessions;

    public NotificationService(NotificationMapper mapper, NotificationSessionRegistry sessions) {
        this.mapper = mapper;
        this.sessions = sessions;
    }

    public PageResult<Map<String, Object>> list(Long userId, String region, Integer page, Integer pageSize) {
        int normalizedPage = page == null || page < 1 ? 1 : page;
        int normalizedSize = pageSize == null ? 20 : Math.max(1, Math.min(pageSize, 100));
        long total = mapper.count(userId, region);
        List<Map<String, Object>> items = mapper.list(userId, region, (normalizedPage - 1) * normalizedSize, normalizedSize)
                .stream().map(this::toResponse).toList();
        return new PageResult<>(items, total, normalizedPage, normalizedSize, (long) normalizedPage * normalizedSize < total);
    }

    public Map<String, Object> unreadCount(Long userId, String region) {
        return Map.of("count", mapper.countUnread(userId, region));
    }

    @Transactional
    public Map<String, Object> ack(Long id, Long userId, String region) {
        NotificationRow row = mapper.findOwned(id, userId, region);
        if (row == null) throw new NotFoundException("通知不存在");
        mapper.markRead(id, userId, region);
        row = mapper.findOwned(id, userId, region);
        return toResponse(row);
    }

    @Transactional
    public Map<String, Object> create(Long userId, String region, String type, String title, String content, String linkUrl) {
        return create(userId, null, region, type, title, content, linkUrl);
    }

    @Transactional
    public Map<String, Object> create(Long userId, Long actorUserId, String region, String type, String title, String content, String linkUrl) {
        NotificationRow row = new NotificationRow();
        row.setUserId(userId); row.setActorUserId(actorUserId); row.setRegion(region); row.setType(type); row.setTitle(title);
        row.setContent(content == null ? "" : content); row.setLinkUrl(linkUrl == null ? "" : linkUrl);
        mapper.insert(row);
        NotificationRow stored = mapper.findOwned(row.getId(), userId, region);
        Map<String, Object> response = toResponse(stored);
        Runnable send = () -> {
            if ("GLOBAL".equals(region)) sessions.sendAllRegions(userId, Map.of("type", "notification.new", "data", response));
            else sessions.send(userId, region, Map.of("type", "notification.new", "data", response));
        };
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCommit() { send.run(); }
            });
        } else send.run();
        return response;
    }

    private Map<String, Object> toResponse(NotificationRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId()); result.put("type", row.getType()); result.put("title", row.getTitle());
        result.put("actorUserId", row.getActorUserId());
        result.put("content", row.getContent()); result.put("linkUrl", row.getLinkUrl());
        result.put("read", Boolean.TRUE.equals(row.getRead()));
        result.put("readAt", row.getReadAt() == null ? "" : row.getReadAt().format(FORMATTER));
        result.put("createdAt", row.getCreatedAt() == null ? "" : row.getCreatedAt().format(FORMATTER));
        return result;
    }
}
