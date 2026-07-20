package com.tuowei.dazhongdianping.module.admin.auth.controller;

import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.model.request.AdminLoginRequest;
import com.tuowei.dazhongdianping.module.admin.auth.model.response.AdminLoginResponse;
import com.tuowei.dazhongdianping.module.admin.auth.model.response.AdminMeResponse;
import com.tuowei.dazhongdianping.module.admin.auth.model.response.AdminMenuResponse;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminAuthService;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminMenuService;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Comparator;
import java.util.List;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1")
public class AdminAuthController {

    private final AdminAuthService adminAuthService;
    private final AdminMenuService adminMenuService;

    public AdminAuthController(AdminAuthService adminAuthService, AdminMenuService adminMenuService) {
        this.adminAuthService = adminAuthService;
        this.adminMenuService = adminMenuService;
    }

    @PostMapping("/auth/login")
    public ApiResponse<AdminLoginResponse> login(@Valid @RequestBody AdminLoginRequest request,
                                                 HttpServletRequest httpServletRequest) {
        AdminAuthService.AdminLoginResult result = adminAuthService.login(
                request.account(), request.password(), clientIp(httpServletRequest));
        List<String> permissions = sorted(result.session().permissions());
        List<String> regions = sorted(result.session().regions());
        return ApiResponse.success(
                "登录成功",
                "admin.login_success",
                new AdminLoginResponse(
                        result.accessToken(),
                        "Bearer",
                        new AdminLoginResponse.AdminProfile(
                                result.session().adminId(),
                                result.session().account(),
                                result.session().name()
                        ),
                        permissions,
                        regions
                )
        );
    }

    @GetMapping("/auth/me")
    public ApiResponse<AdminMeResponse> me() {
        var session = AdminSessionContext.get();
        return ApiResponse.success(new AdminMeResponse(
                new AdminLoginResponse.AdminProfile(session.adminId(), session.account(), session.name()),
                sorted(session.permissions()),
                sorted(session.regions())
        ));
    }

    @PostMapping("/auth/logout")
    public ApiResponse<Void> logout(@RequestHeader(HttpHeaders.AUTHORIZATION) String authorization) {
        adminAuthService.logout(authorization.substring("Bearer ".length()));
        return ApiResponse.success("退出成功", "admin.logout_success", null);
    }

    @GetMapping("/menus")
    public ApiResponse<List<AdminMenuResponse>> menus() {
        return ApiResponse.success(adminMenuService.menus(AdminSessionContext.get().permissions()));
    }

    private List<String> sorted(java.util.Set<String> values) {
        return values.stream().sorted(Comparator.naturalOrder()).toList();
    }

    private String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",", 2)[0].trim();
        }
        return request.getRemoteAddr() == null ? "" : request.getRemoteAddr();
    }
}
