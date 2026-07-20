package com.tuowei.dazhongdianping.module.browse.model.response;

import java.math.BigDecimal;

public record DishResponse(
        Long id,
        String name,
        BigDecimal price,
        String recommendReason
) {
}
