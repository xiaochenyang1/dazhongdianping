package com.tuowei.dazhongdianping.common.riskcontrol;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 从请求头/连接信息提取设备指纹与客户端 IP，写入 {@link RiskRequestContext}。
 * 全局注册（不限白名单），请求结束清理 ThreadLocal。
 */
@Component
public class RiskRequestInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String device = request.getHeader(RiskRequestContext.DEVICE_HEADER);
        RiskRequestContext.set(StringUtils.hasText(device) ? device.trim() : null, resolveIp(request));
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        RiskRequestContext.clear();
    }

    private String resolveIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (StringUtils.hasText(forwarded)) {
            int comma = forwarded.indexOf(',');
            return comma > 0 ? forwarded.substring(0, comma).trim() : forwarded.trim();
        }
        return request.getRemoteAddr() == null ? "" : request.getRemoteAddr();
    }
}
