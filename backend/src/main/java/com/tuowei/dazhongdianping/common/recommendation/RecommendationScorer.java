package com.tuowei.dazhongdianping.common.recommendation;

/**
 * 推荐打分策略 SPI。放在 common.recommendation 而非 module 包下，
 * 以避开 {@code @MapperScan("...module")} 把 module 包下所有接口当成 MyBatis
 * Mapper 代理导致的启动 BindingException（同 verification / push 的约束）。
 */
public interface RecommendationScorer {

    /**
     * 给单个候选店铺打分，分值越高越靠前。
     *
     * @param candidate 候选店铺特征
     * @param context   用户上下文与归一化参照
     * @param weights   区域权重配置
     * @return 综合得分
     */
    double score(RecommendationCandidate candidate,
                 RecommendationContext context,
                 RecommendationWeights weights);
}
