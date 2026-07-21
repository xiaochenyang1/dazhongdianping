package com.tuowei.dazhongdianping.module.browse.mapper;

import com.tuowei.dazhongdianping.module.browse.model.AreaRow;
import com.tuowei.dazhongdianping.module.browse.model.BannerRow;
import com.tuowei.dazhongdianping.module.browse.model.CategoryRow;
import com.tuowei.dazhongdianping.module.browse.model.CityRow;
import com.tuowei.dazhongdianping.module.browse.model.DishRow;
import com.tuowei.dazhongdianping.module.browse.model.HomeFeedRow;
import com.tuowei.dazhongdianping.module.browse.model.HotKeywordRow;
import com.tuowei.dazhongdianping.module.browse.model.PhotoRow;
import com.tuowei.dazhongdianping.module.browse.model.ReviewRow;
import com.tuowei.dazhongdianping.module.browse.model.SearchSuggestionRow;
import com.tuowei.dazhongdianping.module.browse.model.SearchHistoryRow;
import com.tuowei.dazhongdianping.module.browse.model.ShopDetailRow;
import com.tuowei.dazhongdianping.module.browse.model.ShopListQuery;
import com.tuowei.dazhongdianping.module.browse.model.ShopListRow;
import java.math.BigDecimal;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface BrowseQueryMapper {

    List<CategoryRow> selectCategoriesByRegion(@Param("region") String region);

    List<CityRow> selectCitiesByRegion(@Param("region") String region);

    List<AreaRow> selectAreasByRegionAndCity(@Param("region") String region, @Param("cityId") Long cityId);

    List<BannerRow> selectHomeBanners(@Param("region") String region, @Param("cityId") Long cityId);

    List<HomeFeedRow> selectHomeFeed(@Param("region") String region, @Param("cityId") Long cityId, @Param("limit") Integer limit);

    List<HotKeywordRow> selectConfiguredHotKeywords(@Param("region") String region, @Param("limit") Integer limit);

    long countShops(ShopListQuery query);

    List<ShopListRow> selectShops(ShopListQuery query);

    ShopDetailRow selectShopDetail(@Param("region") String region, @Param("shopId") Long shopId);

    List<ShopListRow> selectSimilarShops(@Param("region") String region,
                                         @Param("shopId") Long shopId,
                                         @Param("categoryId") Long categoryId,
                                         @Param("cityId") Long cityId,
                                         @Param("areaId") Long areaId);

    List<PhotoRow> selectShopPhotos(@Param("shopId") Long shopId);

    List<DishRow> selectShopDishes(@Param("shopId") Long shopId);

    long countShopReviews(@Param("region") String region,
                          @Param("shopId") Long shopId,
                          @Param("minScore") BigDecimal minScore,
                          @Param("hasImages") Boolean hasImages);

    List<ReviewRow> selectShopReviews(@Param("region") String region,
                                      @Param("shopId") Long shopId,
                                      @Param("sort") String sort,
                                      @Param("minScore") BigDecimal minScore,
                                      @Param("hasImages") Boolean hasImages,
                                      @Param("limit") Integer limit,
                                      @Param("offset") Integer offset);

    List<SearchSuggestionRow> selectShopSuggestions(@Param("region") String region,
                                                    @Param("keyword") String keyword,
                                                    @Param("limit") Integer limit);

    List<SearchSuggestionRow> selectCategorySuggestions(@Param("region") String region,
                                                        @Param("keyword") String keyword,
                                                        @Param("limit") Integer limit);

    List<String> selectCategoryNamesByRegion(@Param("region") String region);

    List<String> selectActiveShopTagsByRegion(@Param("region") String region);

    List<String> selectApprovedReviewTagsByRegion(@Param("region") String region);

    SearchHistoryRow selectSearchHistoryByUserRegionKeyword(@Param("userId") Long userId,
                                                            @Param("region") String region,
                                                            @Param("keyword") String keyword);

    void insertSearchHistory(SearchHistoryRow row);

    int touchSearchHistory(@Param("id") Long id);

    long countSearchHistory(@Param("userId") Long userId, @Param("region") String region);

    List<SearchHistoryRow> selectSearchHistory(@Param("userId") Long userId,
                                               @Param("region") String region,
                                               @Param("limit") Integer limit,
                                               @Param("offset") Integer offset);

    int deleteSearchHistory(@Param("userId") Long userId, @Param("region") String region);

    void incrementShopView(@Param("shopId") Long shopId, @Param("bizDate") java.time.LocalDate bizDate);
}
