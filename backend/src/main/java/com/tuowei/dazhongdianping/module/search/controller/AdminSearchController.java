package com.tuowei.dazhongdianping.module.search.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.search.service.ShopSearchIndexService;
import java.util.Map;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/search")
public class AdminSearchController {

    private final ShopSearchIndexService shopSearchIndexService;

    public AdminSearchController(ShopSearchIndexService shopSearchIndexService) {
        this.shopSearchIndexService = shopSearchIndexService;
    }

    @PostMapping("/reindex")
    @AdminPermission("data:search_index:write")
    public ApiResponse<Map<String, Integer>> rebuildShopIndex() {
        int indexed = shopSearchIndexService.rebuildAll();
        return ApiResponse.success(
                "商户搜索索引已重建",
                "admin.search_reindex_success",
                Map.of("indexed", indexed)
        );
    }
}
