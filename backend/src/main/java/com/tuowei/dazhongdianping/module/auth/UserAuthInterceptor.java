package com.tuowei.dazhongdianping.module.auth;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.service.PublicAuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class UserAuthInterceptor implements HandlerInterceptor {

    private final PublicAuthService publicAuthService;

    public UserAuthInterceptor(PublicAuthService publicAuthService) {
        this.publicAuthService = publicAuthService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String authorization = request.getHeader("Authorization");
        if (isPublicReviewReadRequest(request) || isPublicPostReadRequest(request)
                || isPublicUserProfileReadRequest(request) || isPublicShopListRequest(request)
                || isPublicCircleReadRequest(request) || isPublicTopicReadRequest(request)) {
            if (StringUtils.hasText(authorization) && authorization.startsWith("Bearer ")) {
                UserSessionContext.set(publicAuthService.authenticate(authorization.substring(7)));
            }
            return true;
        }
        if (!StringUtils.hasText(authorization) || !authorization.startsWith("Bearer ")) {
            throw new UnauthorizedException("缺少有效的用户登录凭证");
        }
        UserSessionContext.set(publicAuthService.authenticate(authorization.substring(7)));
        return true;
    }

    private boolean isPublicReviewReadRequest(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && request.getRequestURI() != null
                && request.getRequestURI().startsWith("/api/c/v1/reviews/");
    }

    private boolean isPublicUserProfileReadRequest(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && request.getRequestURI() != null
                && request.getRequestURI().matches("^/api/c/v1/user/\\d+(/followers|/following)?$");
    }

    private boolean isPublicPostReadRequest(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && request.getRequestURI() != null
                && ("/api/c/v1/posts".equals(request.getRequestURI())
                || request.getRequestURI().startsWith("/api/c/v1/posts/"));
    }

    private boolean isPublicShopListRequest(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && "/api/c/v1/shops".equals(request.getRequestURI());
    }

    private boolean isPublicCircleReadRequest(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && request.getRequestURI() != null
                && request.getRequestURI().matches("^/api/c/v1/groups(/\\d+(/members|/posts)?)?$");
    }

    private boolean isPublicTopicReadRequest(HttpServletRequest request) {
        return "GET".equalsIgnoreCase(request.getMethod())
                && request.getRequestURI() != null
                && request.getRequestURI().matches("^/api/c/v1/topics(?:/hot|/\\d+(?:/posts)?)?$");
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        UserSessionContext.clear();
    }
}
