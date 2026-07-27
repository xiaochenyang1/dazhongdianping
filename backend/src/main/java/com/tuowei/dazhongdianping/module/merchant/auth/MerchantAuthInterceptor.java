package com.tuowei.dazhongdianping.module.merchant.auth;

import com.tuowei.dazhongdianping.common.api.ForbiddenException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.service.MerchantAuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class MerchantAuthInterceptor implements HandlerInterceptor {

    private final MerchantAuthService merchantAuthService;

    public MerchantAuthInterceptor(MerchantAuthService merchantAuthService) {
        this.merchantAuthService = merchantAuthService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String authorization = request.getHeader("Authorization");
        if (!StringUtils.hasText(authorization) || !authorization.startsWith("Bearer ")) {
            throw new UnauthorizedException("缺少有效的商户登录凭证");
        }
        MerchantSession session = merchantAuthService.authenticate(authorization.substring(7));
        if (!session.region().equals(RegionContext.getRegion().name())) {
            throw new ForbiddenException("当前区域无权访问该商户工作台");
        }
        MerchantSessionContext.set(session);
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        MerchantSessionContext.clear();
    }
}
