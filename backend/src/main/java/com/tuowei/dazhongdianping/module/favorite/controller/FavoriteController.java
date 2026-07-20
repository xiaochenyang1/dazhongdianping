package com.tuowei.dazhongdianping.module.favorite.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.favorite.model.FavoriteQuery;
import com.tuowei.dazhongdianping.module.favorite.model.request.FavoriteSaveRequest;
import com.tuowei.dazhongdianping.module.favorite.model.response.FavoriteResponse;
import com.tuowei.dazhongdianping.module.favorite.service.FavoriteService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/favorites")
public class FavoriteController {
    private final FavoriteService favoriteService;
    public FavoriteController(FavoriteService favoriteService) { this.favoriteService = favoriteService; }
    @PostMapping public ApiResponse<FavoriteResponse> add(@Valid @RequestBody FavoriteSaveRequest request) { return ApiResponse.success(favoriteService.add(request)); }
    @DeleteMapping public ApiResponse<Void> remove(@RequestParam Integer targetType, @RequestParam Long targetId) { favoriteService.remove(targetType, targetId); return ApiResponse.success(null); }
    @GetMapping public ApiResponse<PageResult<FavoriteResponse>> list(@Valid FavoriteQuery query) { return ApiResponse.success(favoriteService.list(query)); }
}
