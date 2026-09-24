package com.tuowei.dazhongdianping.config;

import com.tuowei.dazhongdianping.common.region.RegionInterceptor;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRequestInterceptor;
import com.tuowei.dazhongdianping.module.admin.auth.AdminAuthInterceptor;
import com.tuowei.dazhongdianping.module.auth.UserAuthInterceptor;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantAuthInterceptor;
import com.tuowei.dazhongdianping.module.openapi.auth.OpenApiAuthInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final RegionInterceptor regionInterceptor;
    private final RiskRequestInterceptor riskRequestInterceptor;
    private final AdminAuthInterceptor adminAuthInterceptor;
    private final UserAuthInterceptor userAuthInterceptor;
    private final MerchantAuthInterceptor merchantAuthInterceptor;
    private final OpenApiAuthInterceptor openApiAuthInterceptor;
    private final CorsProperties corsProperties;

    public WebMvcConfig(RegionInterceptor regionInterceptor,
                        RiskRequestInterceptor riskRequestInterceptor,
                        AdminAuthInterceptor adminAuthInterceptor,
                        UserAuthInterceptor userAuthInterceptor,
                        MerchantAuthInterceptor merchantAuthInterceptor,
                        OpenApiAuthInterceptor openApiAuthInterceptor,
                        CorsProperties corsProperties) {
        this.regionInterceptor = regionInterceptor;
        this.riskRequestInterceptor = riskRequestInterceptor;
        this.adminAuthInterceptor = adminAuthInterceptor;
        this.userAuthInterceptor = userAuthInterceptor;
        this.merchantAuthInterceptor = merchantAuthInterceptor;
        this.openApiAuthInterceptor = openApiAuthInterceptor;
        this.corsProperties = corsProperties;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(regionInterceptor);
        registry.addInterceptor(riskRequestInterceptor);
        registry.addInterceptor(adminAuthInterceptor)
                .addPathPatterns("/api/admin/v1/**")
                .excludePathPatterns("/api/admin/v1/auth/login");
        registry.addInterceptor(merchantAuthInterceptor)
                .addPathPatterns("/api/b/v1/**")
                .excludePathPatterns(
                        "/api/b/v1/health",
                        "/api/b/v1/auth/login",
                        "/api/b/v1/auth/register"
                );
        registry.addInterceptor(userAuthInterceptor)
                .addPathPatterns(
                        "/api/c/v1/user/**",
                        "/api/c/v1/auth/logout",
                        "/api/c/v1/reviews/**",
                        "/api/c/v1/posts",
                        "/api/c/v1/posts/**",
                        "/api/c/v1/privacy/**",
                        "/api/c/v1/files/upload",
                        "/api/c/v1/shops",
                        "/api/c/v1/shops/**",
                        "/api/c/v1/search/shops",
                        "/api/c/v1/search/history",
                        "/api/c/v1/search/history/**"
                        ,"/api/c/v1/favorites"
                        ,"/api/c/v1/orders","/api/c/v1/orders/**","/api/c/v1/coupons","/api/c/v1/coupons/**"
                        ,"/api/c/v1/reservations","/api/c/v1/reservations/**"
                        ,"/api/c/v1/notifications","/api/c/v1/notifications/**","/api/c/v1/ws/ticket"
                        ,"/api/c/v1/devices","/api/c/v1/devices/**"
                        ,"/api/c/v1/follow/**"
                        ,"/api/c/v1/messages/**"
                        ,"/api/c/v1/groups/**"
                        ,"/api/c/v1/topics","/api/c/v1/topics/**"
                        ,"/api/c/v1/points","/api/c/v1/points/**"
                        ,"/api/c/v1/recommendations/behaviors"
                        ,"/api/c/v1/marketing/coupons/*/claim"
                        ,"/api/c/v1/marketing/coupons/mine"
                        ,"/api/c/v1/deals/*/usable-coupons"
                        ,"/api/c/v1/complaints","/api/c/v1/complaints/**"
                        ,"/api/c/v1/consult","/api/c/v1/consult/**"
                        ,"/api/c/v1/waitlist","/api/c/v1/waitlist/**"
                        ,"/api/c/v1/invoices","/api/c/v1/invoices/**"
                        ,"/api/c/v1/creator/**"
                        ,"/api/c/v1/tickets","/api/c/v1/tickets/**"
                        ,"/api/c/v1/marketing/seckill","/api/c/v1/marketing/seckill/**"
                        ,"/api/c/v1/marketing/groupbuy","/api/c/v1/marketing/groupbuy/**"
                        ,"/api/c/v1/experiments","/api/c/v1/experiments/**"
                );
        registry.addInterceptor(openApiAuthInterceptor)
                .addPathPatterns("/api/open/v1/**");
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns(corsProperties.getAllowedOriginPatterns().toArray(String[]::new))
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .exposedHeaders("X-Trace-Id", "X-Region", "Retry-After");
    }
}
