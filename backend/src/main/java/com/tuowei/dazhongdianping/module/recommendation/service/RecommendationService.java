package com.tuowei.dazhongdianping.module.recommendation.service;

import com.tuowei.dazhongdianping.common.recommendation.RecommendationCandidate;
import com.tuowei.dazhongdianping.common.recommendation.RecommendationContext;
import com.tuowei.dazhongdianping.common.recommendation.RecommendationScorer;
import com.tuowei.dazhongdianping.common.recommendation.RecommendationWeights;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.recommendation.mapper.RecommendationMapper;
import com.tuowei.dazhongdianping.module.recommendation.model.CandidateShopRow;
import com.tuowei.dazhongdianping.module.recommendation.model.CategoryAffinityRow;
import com.tuowei.dazhongdianping.module.recommendation.model.RecommendationWeightRow;
import com.tuowei.dazhongdianping.module.recommendation.model.request.BehaviorEventRequest;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 个性化推荐 C 端服务：基于用户行为偏好 + 店铺质量 + 热度 + 距离的加权召回排序。
 * 匿名用户走冷启动（无品类偏好，按质量/热度/距离排）。
 */
@Service
public class RecommendationService {

    /** 候选召回上限，打分后再截断到请求 limit。 */
    private static final int CANDIDATE_POOL = 200;
    /** 参与偏好聚合的品类数上限。 */
    private static final int AFFINITY_TOP = 20;

    private final RecommendationMapper mapper;
    private final RecommendationScorer scorer;

    public RecommendationService(RecommendationMapper mapper, RecommendationScorer scorer) {
        this.mapper = mapper;
        this.scorer = scorer;
    }

    /** 记录一条用户行为埋点（需登录）。 */
    @Transactional
    public void trackBehavior(BehaviorEventRequest request) {
        UserSession session = UserSessionContext.get();
        if (session == null) {
            return;
        }
        String region = RegionContext.getRegion().name();
        Long categoryId = request.categoryId();
        if (categoryId == null && request.shopId() != null) {
            categoryId = mapper.selectShopCategory(request.shopId(), region);
        }
        mapper.insertBehaviorEvent(
                session.userId(),
                region,
                request.eventType(),
                request.shopId(),
                categoryId,
                request.keyword(),
                weightForEvent(request.eventType())
        );
    }

    /** 生成"猜你喜欢"店铺 feed。lat/lng 可选，提供时启用就近加权。 */
    public List<ShopListItemResponse> feed(Double latitude, Double longitude, Long cityId, int limit) {
        String region = RegionContext.getRegion().name();
        UserSession session = UserSessionContext.get();

        Map<Long, Integer> affinity = new HashMap<>();
        List<Long> preferredCategories = new ArrayList<>();
        if (session != null) {
            List<CategoryAffinityRow> rows = mapper.selectCategoryAffinity(session.userId(), region, AFFINITY_TOP);
            for (CategoryAffinityRow row : rows) {
                if (row.getCategoryId() != null && row.getAffinity() != null) {
                    affinity.put(row.getCategoryId(), row.getAffinity());
                    preferredCategories.add(row.getCategoryId());
                }
            }
        }

        List<CandidateShopRow> candidates = mapper.selectCandidateShops(
                region, cityId, null, null, CANDIDATE_POOL);
        if (candidates.isEmpty()) {
            return List.of();
        }

        RecommendationWeights weights = resolveWeights(region);
        boolean hasLocation = latitude != null && longitude != null;

        long maxViewCount = candidates.stream()
                .mapToLong(c -> c.getViewCount() == null ? 0L : c.getViewCount())
                .max().orElse(0L);

        Map<Long, Double> distanceByShop = new HashMap<>();
        double maxDistance = 0.0;
        if (hasLocation) {
            for (CandidateShopRow c : candidates) {
                if (c.getLatitude() != null && c.getLongitude() != null) {
                    double d = haversineMeters(latitude, longitude, c.getLatitude(), c.getLongitude());
                    distanceByShop.put(c.getId(), d);
                    maxDistance = Math.max(maxDistance, d);
                }
            }
        }

        RecommendationContext context = new RecommendationContext(affinity, maxViewCount, maxDistance);

        return candidates.stream()
                .sorted(Comparator.comparingDouble((CandidateShopRow c) ->
                        scorer.score(toCandidate(c, distanceByShop), context, weights)).reversed()
                        .thenComparing(c -> c.getScore() == null ? BigDecimal.ZERO : c.getScore(), Comparator.reverseOrder())
                        .thenComparing(CandidateShopRow::getId))
                .limit(Math.max(1, limit))
                .map(c -> toResponse(c, distanceByShop.get(c.getId())))
                .toList();
    }

    private RecommendationCandidate toCandidate(CandidateShopRow c, Map<Long, Double> distanceByShop) {
        return new RecommendationCandidate(
                c.getId(),
                c.getCategoryId(),
                c.getScore() == null ? 0.0 : c.getScore().doubleValue(),
                c.getViewCount() == null ? 0L : c.getViewCount(),
                distanceByShop.get(c.getId())
        );
    }

    private ShopListItemResponse toResponse(CandidateShopRow c, Double distanceMeters) {
        return new ShopListItemResponse(
                c.getId(),
                c.getMerchantId(),
                c.getName(),
                c.getCoverUrl(),
                c.getScore(),
                c.getPricePerCapita(),
                c.getCurrency(),
                c.getAddress(),
                c.getLatitude(),
                c.getLongitude(),
                c.getAreaName(),
                c.getCityName(),
                c.getHasDeal(),
                c.getOpenNow(),
                splitTags(c.getTags()),
                distanceMeters,
                null
        );
    }

    private RecommendationWeights resolveWeights(String region) {
        RecommendationWeightRow row = mapper.selectWeight(region);
        if (row == null) {
            return RecommendationWeights.defaults();
        }
        return new RecommendationWeights(
                doubleOf(row.getAffinityWeight(), 40.0),
                doubleOf(row.getQualityWeight(), 25.0),
                doubleOf(row.getPopularityWeight(), 20.0),
                doubleOf(row.getDistanceWeight(), 15.0)
        );
    }

    private double doubleOf(BigDecimal v, double fallback) {
        return v == null ? fallback : v.doubleValue();
    }

    private int weightForEvent(int eventType) {
        return switch (eventType) {
            case 3 -> 5; // 下单
            case 2 -> 3; // 收藏
            default -> 1; // 浏览 / 搜索
        };
    }

    private List<String> splitTags(String tags) {
        if (tags == null || tags.isBlank()) {
            return List.of();
        }
        List<String> result = new ArrayList<>();
        for (String part : tags.split(",")) {
            String trimmed = part.trim();
            if (!trimmed.isEmpty()) {
                result.add(trimmed);
            }
        }
        return result;
    }

    private double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.pow(Math.sin(dLat / 2), 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.pow(Math.sin(dLng / 2), 2);
        return 2 * 6371000 * Math.asin(Math.min(1.0, Math.sqrt(a)));
    }
}
