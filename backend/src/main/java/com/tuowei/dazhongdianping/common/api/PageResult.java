package com.tuowei.dazhongdianping.common.api;

import java.util.List;

public record PageResult<T>(
        List<T> list,
        long total,
        int page,
        int pageSize,
        boolean hasMore
) {
}
