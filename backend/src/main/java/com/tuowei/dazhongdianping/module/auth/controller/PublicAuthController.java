package com.tuowei.dazhongdianping.module.auth.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthLoginCodeRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthLoginPasswordRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthRegisterRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthRefreshRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthResetPasswordRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthSendCodeRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthSendCodeResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthSessionResponse;
import com.tuowei.dazhongdianping.module.auth.service.PublicAuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/auth")
public class PublicAuthController {

    private final PublicAuthService publicAuthService;

    public PublicAuthController(PublicAuthService publicAuthService) {
        this.publicAuthService = publicAuthService;
    }

    @PostMapping("/send-code")
    public ApiResponse<AuthSendCodeResponse> sendCode(@Valid @RequestBody AuthSendCodeRequest request,
                                                      HttpServletRequest httpServletRequest) {
        return ApiResponse.success(
                "验证码已发送",
                "auth.code_sent",
                publicAuthService.sendCode(request, httpServletRequest.getRemoteAddr())
        );
    }

    @PostMapping("/register")
    public ApiResponse<AuthSessionResponse> register(@Valid @RequestBody AuthRegisterRequest request) {
        return ApiResponse.success(
                "注册成功",
                "auth.register_success",
                publicAuthService.register(request)
        );
    }

    @PostMapping("/login/password")
    public ApiResponse<AuthSessionResponse> loginWithPassword(@Valid @RequestBody AuthLoginPasswordRequest request) {
        return ApiResponse.success(
                "登录成功",
                "auth.login_success",
                publicAuthService.loginWithPassword(request)
        );
    }

    @PostMapping("/login/code")
    public ApiResponse<AuthSessionResponse> loginWithCode(@Valid @RequestBody AuthLoginCodeRequest request) {
        return ApiResponse.success(
                "登录成功",
                "auth.login_success",
                publicAuthService.loginWithCode(request)
        );
    }

    @PostMapping("/refresh")
    public ApiResponse<AuthSessionResponse> refresh(@Valid @RequestBody AuthRefreshRequest request) {
        return ApiResponse.success(
                "刷新成功",
                "auth.refresh_success",
                publicAuthService.refresh(request)
        );
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout() {
        publicAuthService.logout();
        return ApiResponse.success("退出成功", "auth.logout_success", null);
    }

    @PostMapping("/password/reset")
    public ApiResponse<Void> resetPassword(@Valid @RequestBody AuthResetPasswordRequest request) {
        publicAuthService.resetPassword(request);
        return ApiResponse.success("密码重置成功", "auth.password_reset_success", null);
    }
}
