package com.tuowei.dazhongdianping.module.auth.model.response;

public record UserCheckInStatusResponse(
        boolean checkedInToday,
        int streakDays,
        long totalCount,
        int todayGrowthReward,
        int todayPointsReward,
        String lastCheckInAt
) {
}
