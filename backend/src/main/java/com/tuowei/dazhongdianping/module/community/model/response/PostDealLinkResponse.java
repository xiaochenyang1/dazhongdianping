package com.tuowei.dazhongdianping.module.community.model.response;

import java.math.BigDecimal;

public record PostDealLinkResponse(Long id, boolean available, Long shopId, String title,
                                   String coverImage, BigDecimal price, String currency) {}
