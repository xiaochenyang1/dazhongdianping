package com.tuowei.dazhongdianping.module.consult.service;

import com.tuowei.dazhongdianping.module.consult.mapper.ConsultMapper;
import com.tuowei.dazhongdianping.module.consult.model.ConsultMessageRow;
import com.tuowei.dazhongdianping.module.consult.model.ConsultSessionRow;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

/** Bounded keyset reads, shared by both sides of a consultation. Call with the session row locked. */
@Component
public class ConsultMessageReader {
    private final ConsultMapper mapper;
    private final ConsultPresenter presenter;

    public ConsultMessageReader(ConsultMapper mapper, ConsultPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    public static int pageSize(Long beforeId, Long afterId, Integer pageSize) {
        if (beforeId != null && afterId != null) {
            throw new IllegalArgumentException("beforeId 与 afterId 不能同时使用");
        }
        if (beforeId != null && beforeId <= 0 || afterId != null && afterId < 0) {
            throw new IllegalArgumentException("消息游标无效");
        }
        int size = pageSize == null ? 50 : pageSize;
        if (size < 1 || size > 100) throw new IllegalArgumentException("pageSize 必须在 1 到 100 之间");
        return size;
    }

    public Map<String, Object> read(ConsultSessionRow session, int viewerType,
                                    Long beforeId, Long afterId, int pageSize) {
        List<ConsultMessageRow> result = mapper.selectMessages(session.getId(), beforeId, afterId, pageSize + 1);
        boolean hasMore = result.size() > pageSize;
        List<ConsultMessageRow> messages = new ArrayList<>(result.subList(0, Math.min(result.size(), pageSize)));
        if (afterId == null) Collections.reverse(messages);

        // History reads never acknowledge newer messages. A partial catch-up keeps its unread badge
        // until the client has received the tail; sends use the same lock, so no unread increment is lost.
        if (beforeId == null && (afterId == null || !hasMore && !messages.isEmpty())) {
            if (viewerType == 1) {
                mapper.markUserRead(session.getId());
                session.setUserUnread(0);
            } else {
                mapper.markMerchantRead(session.getId());
                session.setMerchantUnread(0);
            }
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("session", presenter.session(session, viewerType));
        body.put("messages", presenter.messages(messages));
        body.put("hasMore", hasMore);
        body.put("nextBeforeId", messages.isEmpty() ? null : messages.get(0).getId());
        body.put("nextAfterId", messages.isEmpty() ? (afterId == null ? 0L : afterId)
                : messages.get(messages.size() - 1).getId());
        return body;
    }
}
