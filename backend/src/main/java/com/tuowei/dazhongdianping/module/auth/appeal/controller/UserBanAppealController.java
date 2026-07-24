package com.tuowei.dazhongdianping.module.auth.appeal.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.auth.appeal.model.request.UserBanAppealQueryRequest;
import com.tuowei.dazhongdianping.module.auth.appeal.model.request.UserBanAppealSubmitRequest;
import com.tuowei.dazhongdianping.module.auth.appeal.model.response.UserBanAppealResponse;
import com.tuowei.dazhongdianping.module.auth.appeal.service.UserBanAppealService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/auth/ban-appeals")
public class UserBanAppealController {

    private final UserBanAppealService service;

    public UserBanAppealController(UserBanAppealService service) {
        this.service = service;
    }

    @PostMapping
    public ApiResponse<UserBanAppealResponse> submitAppeal(@Valid @RequestBody UserBanAppealSubmitRequest request) {
        return ApiResponse.success(service.submitAppeal(request));
    }

    @PostMapping("/query")
    public ApiResponse<UserBanAppealResponse> queryLatestAppeal(@Valid @RequestBody UserBanAppealQueryRequest request) {
        return ApiResponse.success(service.queryLatestAppeal(request));
    }
}
