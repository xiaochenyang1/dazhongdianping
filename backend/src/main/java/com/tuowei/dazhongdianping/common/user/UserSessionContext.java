package com.tuowei.dazhongdianping.common.user;

public final class UserSessionContext {

    private static final ThreadLocal<UserSession> HOLDER = new ThreadLocal<>();

    private UserSessionContext() {
    }

    public static void set(UserSession session) {
        HOLDER.set(session);
    }

    public static UserSession get() {
        return HOLDER.get();
    }

    public static void clear() {
        HOLDER.remove();
    }
}
