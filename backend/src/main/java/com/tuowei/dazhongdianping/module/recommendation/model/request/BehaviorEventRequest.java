package com.tuowei.dazhongdianping.module.recommendation.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * C 端上报一条用户行为埋点。shopId/categoryId/keyword 按 eventType 选填。
 *
 * @param eventType  1=浏览店铺 2=收藏 3=下单 4=搜索关键词
 * @param shopId     关联店铺（浏览/收藏/下单时提供）
 * @param categoryId 关联品类（可选，缺省时后端按 shop 回填）
 * @param keyword    搜索关键词（eventType=4 时提供）
 */
public record BehaviorEventRequest(
        @NotNull @Min(1) @Max(4) Integer eventType,
        Long shopId,
        Long categoryId,
        @Size(max = 64) String keyword
) {
}
