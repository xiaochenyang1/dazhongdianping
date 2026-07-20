package com.tuowei.dazhongdianping.common.region;

public final class RegionContext {

    private static final ThreadLocal<Region> REGION_HOLDER = new ThreadLocal<>();

    private RegionContext() {
    }

    public static void setRegion(Region region) {
        REGION_HOLDER.set(region);
    }

    public static Region getRegion() {
        Region region = REGION_HOLDER.get();
        return region == null ? Region.CN : region;
    }

    public static void clear() {
        REGION_HOLDER.remove();
    }
}
