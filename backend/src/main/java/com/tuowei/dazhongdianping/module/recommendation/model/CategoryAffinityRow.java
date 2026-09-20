package com.tuowei.dazhongdianping.module.recommendation.model;

import lombok.Data;

/**
 * 用户对某品类的累计行为权重，来自 user_behavior_event 聚合。
 */
@Data
public class CategoryAffinityRow {
    private Long categoryId;
    private Integer affinity;
}
