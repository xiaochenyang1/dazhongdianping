package com.tuowei.dazhongdianping.common.recommendation;

import org.springframework.stereotype.Component;

/**
 * 默认的可解释加权打分实现（非 ML）：四个 0-1 归一化因子按区域权重线性加权。
 * <ul>
 *   <li>affinity：用户对该店品类的历史偏好占比</li>
 *   <li>quality：店铺评分 / 5</li>
 *   <li>popularity：浏览热度 / 候选集最大热度</li>
 *   <li>distance：1 - 距离 / 候选集最大距离（越近越高；无位置时该因子记 0）</li>
 * </ul>
 */
@Component
public class WeightedRecommendationScorer implements RecommendationScorer {

    @Override
    public double score(RecommendationCandidate candidate,
                        RecommendationContext context,
                        RecommendationWeights weights) {
        double affinity = affinityFactor(candidate, context);
        double quality = clamp01(candidate.score() / 5.0);
        double popularity = context.maxViewCount() <= 0
                ? 0.0
                : clamp01((double) candidate.viewCount() / context.maxViewCount());
        double distance = distanceFactor(candidate, context);
        return affinity * weights.affinity()
                + quality * weights.quality()
                + popularity * weights.popularity()
                + distance * weights.distance();
    }

    private double affinityFactor(RecommendationCandidate candidate, RecommendationContext context) {
        if (candidate.categoryId() == null || context.categoryAffinity() == null || context.categoryAffinity().isEmpty()) {
            return 0.0;
        }
        int total = context.categoryAffinity().values().stream().mapToInt(Integer::intValue).sum();
        if (total <= 0) {
            return 0.0;
        }
        int matched = context.categoryAffinity().getOrDefault(candidate.categoryId(), 0);
        return clamp01((double) matched / total);
    }

    private double distanceFactor(RecommendationCandidate candidate, RecommendationContext context) {
        if (candidate.distanceMeters() == null || context.maxDistanceMeters() <= 0) {
            return 0.0;
        }
        return clamp01(1.0 - candidate.distanceMeters() / context.maxDistanceMeters());
    }

    private double clamp01(double v) {
        if (v < 0.0) {
            return 0.0;
        }
        return Math.min(v, 1.0);
    }
}
