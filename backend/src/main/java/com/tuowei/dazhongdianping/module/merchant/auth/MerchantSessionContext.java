package com.tuowei.dazhongdianping.module.merchant.auth;

public final class MerchantSessionContext {

    private static final ThreadLocal<MerchantSession> SESSION_HOLDER = new ThreadLocal<>();

    private MerchantSessionContext() {
    }

    public static void set(MerchantSession session) {
        SESSION_HOLDER.set(session);
    }

    public static MerchantSession get() {
        return SESSION_HOLDER.get();
    }

    public static void clear() {
        SESSION_HOLDER.remove();
    }
}
