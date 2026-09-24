package com.tuowei.dazhongdianping.module.openapi.auth;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.region.RegionInterceptor;
import com.tuowei.dazhongdianping.module.openapi.mapper.OpenApiMapper;
import com.tuowei.dazhongdianping.module.openapi.model.OpenApiCredential;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Locale;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * /api/open/v1/** 的 HMAC 验签。通过后把区域切到 open_app.region，不信任客户端 X-Region。
 * 规范串：keyId + "\n" + timestamp + "\n" + METHOD + "\n" + path（不含 query，METHOD 大写）。
 * 签名为 HMAC-SHA256(原始 secret 的 UTF-8, 规范串) 的小写十六进制。
 */
@Component
public class OpenApiAuthInterceptor implements HandlerInterceptor {

    static final String REGION_SET = "openApi.regionSet";
    private static final long MAX_SKEW_MILLIS = 5L * 60L * 1000L;

    private final OpenApiMapper mapper;

    public OpenApiAuthInterceptor(OpenApiMapper mapper) {
        this.mapper = mapper;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String keyId = trim(request.getHeader("X-Open-Key"));
        String timestamp = trim(request.getHeader("X-Open-Timestamp"));
        String signature = trim(request.getHeader("X-Open-Signature"));
        if (!StringUtils.hasText(keyId) || !StringUtils.hasText(timestamp) || !StringUtils.hasText(signature)) {
            throw new UnauthorizedException("缺少开放平台签名凭证");
        }
        long ts;
        try {
            ts = Long.parseLong(timestamp);
        } catch (NumberFormatException ex) {
            throw new UnauthorizedException("开放平台时间戳无效");
        }
        if (Math.abs(System.currentTimeMillis() - ts) > MAX_SKEW_MILLIS) {
            throw new UnauthorizedException("开放平台请求时间戳已过期");
        }
        OpenApiCredential credential = mapper.selectCredential(keyId);
        if (credential == null || credential.getStatus() == null || credential.getStatus() != 1
                || !StringUtils.hasText(credential.getSecretHash())) {
            throw new UnauthorizedException("开放平台密钥不存在或已停用");
        }
        if (credential.getAppStatus() == null || credential.getAppStatus() != 1) {
            throw new UnauthorizedException("开放平台应用已停用");
        }
        String canonical = keyId + "\n" + timestamp + "\n"
                + request.getMethod().toUpperCase(Locale.ROOT) + "\n" + requestPath(request);
        String expected = hmacHex(credential.getSecretHash(), canonical);
        if (!MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                signature.toLowerCase(Locale.ROOT).getBytes(StandardCharsets.UTF_8))) {
            throw new UnauthorizedException("开放平台签名校验失败");
        }
        Region region = Region.valueOf(credential.getRegion());
        RegionContext.setRegion(region);
        request.setAttribute(REGION_SET, Boolean.TRUE);
        response.setHeader(RegionInterceptor.REGION_HEADER, region.name());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        if (Boolean.TRUE.equals(request.getAttribute(REGION_SET))) {
            RegionContext.clear();
        }
    }

    private String requestPath(HttpServletRequest request) {
        String uri = request.getRequestURI();
        String contextPath = request.getContextPath();
        if (contextPath != null && !contextPath.isEmpty() && uri.startsWith(contextPath)) {
            uri = uri.substring(contextPath.length());
        }
        int query = uri.indexOf('?');
        if (query >= 0) {
            uri = uri.substring(0, query);
        }
        return uri;
    }

    private String hmacHex(String secret, String canonical) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(canonical.getBytes(StandardCharsets.UTF_8)));
        } catch (GeneralSecurityException ex) {
            throw new IllegalStateException("HMAC-SHA256 不可用", ex);
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
