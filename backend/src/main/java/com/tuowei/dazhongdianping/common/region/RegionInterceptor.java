package com.tuowei.dazhongdianping.common.region;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class RegionInterceptor implements HandlerInterceptor {

    public static final String REGION_HEADER = "X-Region";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        Region region = Region.fromHeader(request.getHeader(REGION_HEADER));
        RegionContext.setRegion(region);
        response.setHeader(REGION_HEADER, region.name());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        RegionContext.clear();
    }
}
