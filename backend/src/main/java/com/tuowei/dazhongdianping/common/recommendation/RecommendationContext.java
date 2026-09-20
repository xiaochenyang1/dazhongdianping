package com.tuowei.dazhongdianping.common.recommendation;

import java.util.Map;

/**
 * 单次推荐打分的用户侧上下文与归一化参照。
 *
 * @param categoryAffinity 用户对各品类的偏好权重（categoryId -> 累计行为权重），空表示无历史（走冷启动）
 * @param maxViewCount     候选集中最大浏览热度，用于把 viewCount 归一化到 0-1
 * @param maxDistanceMeters 候选集中最大距离，用于把距离归一化（越近得分越高）
 */
public record RecommendationContext(
        Map<Long, Integer> categoryAffinity,
        long maxViewCount,
        double maxDistanceMeters
) {
}
