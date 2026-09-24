package com.tuowei.dazhongdianping.common.recommendation;

/**
 * 推荐打分四维权重（口味偏好/店铺质量/热度/距离）。
 * 由运营在 Admin 后台按区域配置，透传给 {@link RecommendationScorer}。
 */
public record RecommendationWeights(
        double affinity,
        double quality,
        double popularity,
        double distance
) {
    /** 未配置区域时的兜底默认权重。 */
    public static RecommendationWeights defaults() {
        return new RecommendationWeights(40.0, 25.0, 20.0, 15.0);
    }
}
