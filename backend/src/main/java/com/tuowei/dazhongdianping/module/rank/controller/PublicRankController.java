package com.tuowei.dazhongdianping.module.rank.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.rank.model.response.RankDetailResponse;
import com.tuowei.dazhongdianping.module.rank.model.response.RankSummaryResponse;
import com.tuowei.dazhongdianping.module.rank.service.RankService;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/ranks")
public class PublicRankController {
    private final RankService rankService;

    public PublicRankController(RankService rankService) {
        this.rankService = rankService;
    }

    @GetMapping
    public ApiResponse<List<RankSummaryResponse>> list(@RequestParam(required = false) Long cityId,
                                                        @RequestParam(required = false) Long categoryId,
                                                        @RequestParam(required = false) Integer type) {
        return ApiResponse.success(rankService.list(RegionContext.getRegion(), cityId, categoryId, type));
    }

    @GetMapping("/{rankId}")
    public ApiResponse<RankDetailResponse> detail(@PathVariable Long rankId) {
        return ApiResponse.success(rankService.detail(RegionContext.getRegion(), rankId));
    }
}
