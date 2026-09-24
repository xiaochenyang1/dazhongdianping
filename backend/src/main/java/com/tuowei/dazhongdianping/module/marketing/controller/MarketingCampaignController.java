package com.tuowei.dazhongdianping.module.marketing.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.marketing.service.MarketingCampaignService;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/marketing")
public class MarketingCampaignController {

    private final MarketingCampaignService service;

    public MarketingCampaignController(MarketingCampaignService service) {
        this.service = service;
    }

    @GetMapping("/seckill")
    public ApiResponse<List<Map<String, Object>>> seckills() {
        return ApiResponse.success(service.seckills());
    }

    @PostMapping("/seckill/{id}/claim")
    public ApiResponse<Map<String, Object>> claimSeckill(@PathVariable Long id) {
        return ApiResponse.success("秒杀已领取", "marketing.seckill_claimed", service.claimSeckill(id));
    }

    @GetMapping("/groupbuy")
    public ApiResponse<List<Map<String, Object>>> groupBuys() {
        return ApiResponse.success(service.groupBuys());
    }

    @PostMapping("/groupbuy/{id}/teams")
    public ApiResponse<Map<String, Object>> openTeam(@PathVariable Long id) {
        return ApiResponse.success("已开团", "marketing.group_opened", service.openTeam(id));
    }

    @PostMapping("/groupbuy/teams/{teamId}/join")
    public ApiResponse<Map<String, Object>> joinTeam(@PathVariable Long teamId) {
        return ApiResponse.success("已参团", "marketing.group_joined", service.joinTeam(teamId));
    }
}
