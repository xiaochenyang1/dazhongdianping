package com.tuowei.dazhongdianping.module.auth.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.auth.model.UserGrowthRecordQuery;
import com.tuowei.dazhongdianping.module.auth.model.request.UserBindRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserPasswordUpdateRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserProfileUpdateRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthCurrentUserResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.UserGrowthRecordResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.UserPublicProfileResponse;
import com.tuowei.dazhongdianping.module.auth.service.PublicAuthService;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/c/v1/user")
public class UserProfileController {

    private final PublicAuthService publicAuthService;
    private final UserGrowthService userGrowthService;

    public UserProfileController(PublicAuthService publicAuthService, UserGrowthService userGrowthService) {
        this.publicAuthService = publicAuthService;
        this.userGrowthService = userGrowthService;
    }

    @GetMapping("/me")
    public ApiResponse<AuthCurrentUserResponse> me() {
        return ApiResponse.success(publicAuthService.currentUser());
    }

    @GetMapping("/growth/records")
    public ApiResponse<PageResult<UserGrowthRecordResponse>> listGrowthRecords(@Valid UserGrowthRecordQuery query) {
        return ApiResponse.success(userGrowthService.listCurrentUserGrowthRecords(query));
    }

    @PutMapping("/profile")
    public ApiResponse<AuthCurrentUserResponse> updateProfile(@Valid @RequestBody UserProfileUpdateRequest request) {
        return ApiResponse.success(
                "资料已更新",
                "user.profile_updated",
                publicAuthService.updateCurrentUserProfile(request)
        );
    }

    @PostMapping("/bind")
    public ApiResponse<AuthCurrentUserResponse> bindAccount(@Valid @RequestBody UserBindRequest request) {
        return ApiResponse.success(
                "账号已绑定",
                "user.account_bound",
                publicAuthService.bindCurrentUser(request)
        );
    }

    @PutMapping("/password")
    public ApiResponse<Void> updatePassword(@Valid @RequestBody UserPasswordUpdateRequest request) {
        publicAuthService.updateCurrentUserPassword(request);
        return ApiResponse.success("密码已更新", "user.password_updated", null);
    }

    @GetMapping("/{userId}")
    public ApiResponse<UserPublicProfileResponse> getPublicProfile(@PathVariable Long userId) {
        return ApiResponse.success(publicAuthService.getPublicUserProfile(userId));
    }
}
