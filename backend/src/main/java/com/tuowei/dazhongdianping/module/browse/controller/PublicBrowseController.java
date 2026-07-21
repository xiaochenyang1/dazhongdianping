package com.tuowei.dazhongdianping.module.browse.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.browse.model.ShopListQuery;
import com.tuowei.dazhongdianping.module.browse.model.response.AreaResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.BannerResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.CategoryNodeResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.CityResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.HomeFeedItemResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.ReviewPreviewResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.SearchHotWordResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.SearchHistoryResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.SearchSuggestionResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopDetailResponse;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.browse.service.BrowseQueryService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/c/v1")
public class PublicBrowseController {

    private final BrowseQueryService browseQueryService;

    public PublicBrowseController(BrowseQueryService browseQueryService) {
        this.browseQueryService = browseQueryService;
    }

    @GetMapping("/categories")
    public ApiResponse<List<CategoryNodeResponse>> listCategories() {
        return ApiResponse.success(browseQueryService.listCategories(currentRegion()));
    }

    @GetMapping("/cities")
    public ApiResponse<List<CityResponse>> listCities() {
        return ApiResponse.success(browseQueryService.listCities(currentRegion()));
    }

    @GetMapping("/cities/{cityId}/areas")
    public ApiResponse<List<AreaResponse>> listAreas(@PathVariable Long cityId) {
        return ApiResponse.success(browseQueryService.listAreas(currentRegion(), cityId));
    }

    @GetMapping("/home/banners")
    public ApiResponse<List<BannerResponse>> listHomeBanners(@RequestParam(required = false) Long cityId) {
        return ApiResponse.success(browseQueryService.listHomeBanners(currentRegion(), cityId));
    }

    @GetMapping("/home/feed")
    public ApiResponse<List<HomeFeedItemResponse>> listHomeFeed(@RequestParam(required = false) Long cityId,
                                                                @RequestParam(defaultValue = "6") Integer limit) {
        return ApiResponse.success(browseQueryService.listHomeFeed(currentRegion(), cityId, limit));
    }

    @GetMapping("/shops")
    public ApiResponse<PageResult<ShopListItemResponse>> listShops(@Valid ShopListQuery query) {
        return ApiResponse.success(browseQueryService.listShops(currentRegion(), query));
    }

    @GetMapping("/shops/{shopId}")
    public ApiResponse<ShopDetailResponse> getShopDetail(@PathVariable Long shopId) {
        return ApiResponse.success(browseQueryService.getShopDetail(currentRegion(), shopId));
    }

    @GetMapping("/shops/{shopId}/similar")
    public ApiResponse<List<ShopListItemResponse>> listSimilarShops(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "6")
            @Min(value = 1, message = "limit 最小为 1")
            @Max(value = 12, message = "limit 最大为 12") Integer limit) {
        return ApiResponse.success(browseQueryService.listSimilarShops(currentRegion(), shopId, limit));
    }

    @GetMapping("/shops/{shopId}/reviews")
    public ApiResponse<PageResult<ReviewPreviewResponse>> listShopReviews(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "1") @Min(value = 1, message = "page 最小为 1") Integer page,
            @RequestParam(defaultValue = "10")
            @Min(value = 1, message = "pageSize 最小为 1")
            @Max(value = 50, message = "pageSize 最大为 50") Integer pageSize,
            @RequestParam(defaultValue = "latest") String sort,
            @RequestParam(required = false) BigDecimal minScore,
            @RequestParam(required = false) Boolean hasImages) {
        return ApiResponse.success(browseQueryService.listShopReviews(
                currentRegion(), shopId, page, pageSize, sort, minScore, hasImages));
    }

    @GetMapping("/search/suggest")
    public ApiResponse<List<SearchSuggestionResponse>> listSearchSuggestions(@RequestParam("kw") String keyword,
                                                                             @RequestParam(defaultValue = "8") Integer limit) {
        return ApiResponse.success(browseQueryService.listSearchSuggestions(currentRegion(), keyword, limit));
    }

    @GetMapping("/search/hot")
    public ApiResponse<List<SearchHotWordResponse>> listHotSearchWords(@RequestParam(defaultValue = "8") Integer limit) {
        return ApiResponse.success(browseQueryService.listHotSearchWords(currentRegion(), limit));
    }

    @GetMapping("/search/history")
    public ApiResponse<PageResult<SearchHistoryResponse>> listSearchHistory(@RequestParam(defaultValue = "1") Integer page,
                                                                            @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(browseQueryService.listSearchHistory(currentRegion(), page, pageSize));
    }

    @DeleteMapping("/search/history")
    public ApiResponse<Void> clearSearchHistory() {
        browseQueryService.clearSearchHistory(currentRegion());
        return ApiResponse.success("搜索历史已清空", "search.history_cleared", null);
    }

    private Region currentRegion() {
        return RegionContext.getRegion();
    }
}
