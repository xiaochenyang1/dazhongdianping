package com.tuowei.dazhongdianping.common.region;

import java.util.Locale;

public enum Region {
    CN,
    EU;

    public static Region fromHeader(String value) {
        if (value == null || value.isBlank()) {
            return CN;
        }
        return Region.valueOf(value.trim().toUpperCase(Locale.ROOT));
    }
}
