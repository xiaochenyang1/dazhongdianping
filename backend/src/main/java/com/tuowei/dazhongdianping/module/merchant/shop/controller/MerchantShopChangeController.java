package com.tuowei.dazhongdianping.module.merchant.shop.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangeDishesRequest;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangePhotosRequest;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangeSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.shop.service.MerchantShopChangeService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/b/v1")
public class MerchantShopChangeController {

    private final MerchantShopChangeService service;

    public MerchantShopChangeController(MerchantShopChangeService service) {
        this.service = service;
    }

    @GetMapping("/shop-changes")
    public ApiResponse<PageResult<Map<String, Object>>> list(
            @RequestParam(required = false) Long shopId,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Integer changeType,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer pageSize
    ) {
        return ApiResponse.success(service.list(shopId, status, changeType, page, pageSize));
    }

    @GetMapping("/shop-changes/{id}")
    public ApiResponse<Map<String, Object>> detail(@PathVariable Long id) {
        return ApiResponse.success(service.detail(id));
    }

    @PostMapping("/shops/change-drafts")
    public ApiResponse<Map<String, Object>> createNewDraft() {
        return ApiResponse.success("门店草稿已创建", "merchant.shop_draft_created", service.createNewDraft());
    }

    @PostMapping("/shops/{shopId}/change-drafts")
    public ApiResponse<Map<String, Object>> createUpdateDraft(@PathVariable Long shopId) {
        return ApiResponse.success("门店草稿已创建", "merchant.shop_draft_created",
                service.createUpdateDraft(shopId));
    }

    @PutMapping("/shop-changes/{id}")
    public ApiResponse<Map<String, Object>> save(
            @PathVariable Long id,
            @Valid @RequestBody ShopChangeSaveRequest request
    ) {
        return ApiResponse.success("门店草稿已保存", "merchant.shop_draft_saved", service.save(id, request));
    }

    @PutMapping("/shop-changes/{id}/photos")
    public ApiResponse<Map<String, Object>> savePhotos(
            @PathVariable Long id,
            @Valid @RequestBody ShopChangePhotosRequest request
    ) {
        return ApiResponse.success("门店相册草稿已保存", "merchant.shop_photos_saved",
                service.savePhotos(id, request));
    }

    @PutMapping("/shop-changes/{id}/dishes")
    public ApiResponse<Map<String, Object>> saveDishes(
            @PathVariable Long id,
            @Valid @RequestBody ShopChangeDishesRequest request
    ) {
        return ApiResponse.success("门店菜单草稿已保存", "merchant.shop_dishes_saved",
                service.saveDishes(id, request));
    }

    @PostMapping("/shop-changes/{id}/submit")
    public ApiResponse<Map<String, Object>> submit(@PathVariable Long id) {
        return ApiResponse.success("门店变更已提交审核", "merchant.shop_change_submitted",
                service.submit(id));
    }
}
