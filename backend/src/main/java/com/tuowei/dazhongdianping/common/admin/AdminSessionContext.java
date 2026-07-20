package com.tuowei.dazhongdianping.common.admin;

public final class AdminSessionContext {

    private static final ThreadLocal<AdminSession> SESSION_HOLDER = new ThreadLocal<>();

    private AdminSessionContext() {
    }

    public static void set(AdminSession session) {
        SESSION_HOLDER.set(session);
    }

    public static AdminSession get() {
        return SESSION_HOLDER.get();
    }

    public static void clear() {
        SESSION_HOLDER.remove();
    }
}
