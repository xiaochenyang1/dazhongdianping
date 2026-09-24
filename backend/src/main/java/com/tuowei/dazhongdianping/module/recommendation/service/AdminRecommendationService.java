package com.tuowei.dazhongdianping.module.recommendation.service;

import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.recommendation.mapper.RecommendationMapper;
import com.tuowei.dazhongdianping.module.recommendation.model.RecommendationWeightRow;
import com.tuowei.dazhongdianping.module.recommendation.model.request.RecommendationWeightSaveRequest;
import com.tuowei.dazhongdianping.module.recommendation.model.response.RecommendationWeightResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Admin 侧推荐权重配置服务，按当前区域读写 recommendation_weight。
 */
@Service
public class AdminRecommendationService {

    private final RecommendationMapper mapper;

    public AdminRecommendationService(RecommendationMapper mapper) {
        this.mapper = mapper;
    }

    public RecommendationWeightResponse currentWeight() {
        String region = RegionContext.getRegion().name();
        RecommendationWeightRow row = mapper.selectWeight(region);
        if (row == null) {
            return new RecommendationWeightResponse(
                    region,
                    java.math.BigDecimal.valueOf(40.00),
                    java.math.BigDecimal.valueOf(25.00),
                    java.math.BigDecimal.valueOf(20.00),
                    java.math.BigDecimal.valueOf(15.00)
            );
        }
        return toResponse(row);
    }

    @Transactional
    public RecommendationWeightResponse saveWeight(RecommendationWeightSaveRequest request) {
        String region = RegionContext.getRegion().name();
        RecommendationWeightRow row = new RecommendationWeightRow();
        row.setRegion(region);
        row.setAffinityWeight(request.affinityWeight());
        row.setQualityWeight(request.qualityWeight());
        row.setPopularityWeight(request.popularityWeight());
        row.setDistanceWeight(request.distanceWeight());
        int updated = mapper.updateWeight(row);
        if (updated == 0) {
            mapper.insertWeight(row);
        }
        return toResponse(row);
    }

    private RecommendationWeightResponse toResponse(RecommendationWeightRow row) {
        return new RecommendationWeightResponse(
                row.getRegion(),
                row.getAffinityWeight(),
                row.getQualityWeight(),
                row.getPopularityWeight(),
                row.getDistanceWeight()
        );
    }
}
