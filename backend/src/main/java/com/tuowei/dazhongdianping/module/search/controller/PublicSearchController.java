package com.tuowei.dazhongdianping.module.search.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;
import com.tuowei.dazhongdianping.module.search.service.ShopSearchService;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/c/v1/search")
public class PublicSearchController {

    private final ShopSearchService shopSearchService;

    public PublicSearchController(ShopSearchService shopSearchService) {
        this.shopSearchService = shopSearchService;
    }

    @GetMapping("/shops")
    public ApiResponse<PageResult<ShopListItemResponse>> searchShops(@Valid ShopSearchQuery query) {
        return ApiResponse.success(shopSearchService.search(RegionContext.getRegion(), query));
    }
}
