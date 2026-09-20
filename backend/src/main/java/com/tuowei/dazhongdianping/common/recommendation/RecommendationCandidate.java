package com.tuowei.dazhongdianping.common.recommendation;

/**
 * 参与推荐打分的候选店铺特征（已从各数据源归一化前的原始特征）。
 *
 * @param shopId         店铺 id
 * @param categoryId     店铺品类 id
 * @param score          店铺评分（0-5）
 * @param viewCount      近期浏览热度（原始计数）
 * @param distanceMeters 与用户的距离（米），无位置时为 null
 */
public record RecommendationCandidate(
        long shopId,
        Long categoryId,
        double score,
        long viewCount,
        Double distanceMeters
) {
}
