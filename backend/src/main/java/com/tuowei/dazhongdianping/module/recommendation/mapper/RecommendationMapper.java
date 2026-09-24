package com.tuowei.dazhongdianping.module.recommendation.mapper;

import com.tuowei.dazhongdianping.module.recommendation.model.CandidateShopRow;
import com.tuowei.dazhongdianping.module.recommendation.model.CategoryAffinityRow;
import com.tuowei.dazhongdianping.module.recommendation.model.RecommendationWeightRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface RecommendationMapper {

    /** 写入一条用户行为埋点。 */
    void insertBehaviorEvent(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("eventType") Integer eventType,
            @Param("shopId") Long shopId,
            @Param("categoryId") Long categoryId,
            @Param("keyword") String keyword,
            @Param("weight") Integer weight
    );

    /** 回填店铺所属品类（上报时未带 categoryId 时用）。 */
    Long selectShopCategory(@Param("shopId") Long shopId, @Param("region") String region);

    /** 聚合用户近期各品类偏好权重。 */
    List<CategoryAffinityRow> selectCategoryAffinity(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("limit") Integer limit
    );

    /** 拉取候选店铺（带近期浏览热度），可按品类集合优先召回。 */
    List<CandidateShopRow> selectCandidateShops(
            @Param("region") String region,
            @Param("cityId") Long cityId,
            @Param("categoryIds") List<Long> categoryIds,
            @Param("excludeShopId") Long excludeShopId,
            @Param("limit") Integer limit
    );

    RecommendationWeightRow selectWeight(@Param("region") String region);

    int updateWeight(RecommendationWeightRow row);

    void insertWeight(RecommendationWeightRow row);
}
