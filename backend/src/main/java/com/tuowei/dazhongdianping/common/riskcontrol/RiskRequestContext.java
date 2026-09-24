package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 请求级风控信息（设备指纹 + 客户端 IP），由 {@code RiskRequestInterceptor} 从请求头填充，
 * 供各挂钩点（点评/下单/注册）无侵入读取，仿 {@code RegionContext} 的 ThreadLocal 模式。
 */
public final class RiskRequestContext {

    /** 前端在请求头携带的设备指纹字段名。 */
    public static final String DEVICE_HEADER = "X-Device-Id";

    private static final ThreadLocal<RiskRequestInfo> HOLDER = new ThreadLocal<>();

    private RiskRequestContext() {
    }

    public static void set(String deviceFingerprint, String ip) {
        HOLDER.set(new RiskRequestInfo(deviceFingerprint, ip));
    }

    public static String deviceFingerprint() {
        RiskRequestInfo info = HOLDER.get();
        return info == null ? null : info.deviceFingerprint();
    }

    public static String ip() {
        RiskRequestInfo info = HOLDER.get();
        return info == null ? null : info.ip();
    }

    public static void clear() {
        HOLDER.remove();
    }

    public record RiskRequestInfo(String deviceFingerprint, String ip) {
    }
}
