package com.tuowei.dazhongdianping.module.consult.service;

import com.tuowei.dazhongdianping.module.consult.model.ConsultSessionRow;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Keyset paging by activity time and ID; the cursor is a boundary, not a snapshot. */
public final class ConsultSessionPage {
    private ConsultSessionPage() {}

    public static int validate(LocalDateTime beforeUpdatedAt, Long beforeId, Integer pageSize) {
        if ((beforeUpdatedAt == null) != (beforeId == null) || beforeId != null && beforeId <= 0) {
            throw new IllegalArgumentException("会话游标必须同时提供有效时间和正整数 ID");
        }
        int size = pageSize == null ? 20 : pageSize;
        if (size < 1 || size > 100) throw new IllegalArgumentException("pageSize 必须在 1 到 100 之间");
        return size;
    }

    public static Map<String, Object> present(List<ConsultSessionRow> rows, int size,
                                             int viewerType, ConsultPresenter presenter) {
        boolean hasMore = rows.size() > size;
        var page = rows.subList(0, Math.min(rows.size(), size));
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("list", presenter.sessions(page, viewerType));
        result.put("hasMore", hasMore);
        var last = hasMore ? page.get(page.size() - 1) : null;
        result.put("nextBeforeId", last == null ? null : last.getId());
        result.put("nextBeforeUpdatedAt", last == null ? null : last.getUpdatedAt());
        return result;
    }
}
