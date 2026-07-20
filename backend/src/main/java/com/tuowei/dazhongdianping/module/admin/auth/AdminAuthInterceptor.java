package com.tuowei.dazhongdianping.module.admin.auth;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminAuthService;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminPermissionChecker;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.method.HandlerMethod;

@Component
public class AdminAuthInterceptor implements HandlerInterceptor {

    private final AdminAuthService adminAuthService;
    private final AdminPermissionChecker permissionChecker;

    public AdminAuthInterceptor(AdminAuthService adminAuthService, AdminPermissionChecker permissionChecker) {
        this.adminAuthService = adminAuthService;
        this.permissionChecker = permissionChecker;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String authorization = request.getHeader("Authorization");
        if (!StringUtils.hasText(authorization) || !authorization.startsWith("Bearer ")) {
            throw new UnauthorizedException("缺少有效的管理员登录凭证");
        }
        String token = authorization.substring(7);
        AdminSession session = adminAuthService.authenticate(token);
        AdminSessionContext.set(session);
        if (handler instanceof HandlerMethod handlerMethod) {
            AdminPermission permission = handlerMethod.getMethodAnnotation(AdminPermission.class);
            if (permission == null) permission = handlerMethod.getBeanType().getAnnotation(AdminPermission.class);
            if (permission != null) {
                permissionChecker.require(session, permission.dynamic() ? "" : permission.value(), permission.regionScoped());
            }
        }
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        AdminSessionContext.clear();
    }
}
