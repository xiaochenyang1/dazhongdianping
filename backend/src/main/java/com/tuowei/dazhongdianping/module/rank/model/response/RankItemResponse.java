package com.tuowei.dazhongdianping.module.rank.model.response;

import java.math.BigDecimal;

public record RankItemResponse(
        Integer position,
        BigDecimal rankScore,
        String reason,
        RankShopResponse shop
) {
}
