package com.tuowei.dazhongdianping.module.trade.service;

import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.CouponLifecycleResult;
import com.tuowei.dazhongdianping.module.trade.model.CouponRow;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CouponLifecycleService {

    private static final Logger log = LoggerFactory.getLogger(CouponLifecycleService.class);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final String REMINDER_TYPE = "coupon.reminder";
    private static final String EXPIRED_TYPE = "coupon.expired";
    private static final int BATCH_SIZE = 100;
    private static final int FLAG_THREE_DAY = 1;
    private static final int FLAG_ONE_DAY = 2;
    private static final int THREE_DAY_WINDOW = 3;
    private static final int ONE_DAY_WINDOW = 1;

    private final TradeMapper tradeMapper;
    private final NotificationService notificationService;

    public CouponLifecycleService(TradeMapper tradeMapper, NotificationService notificationService) {
        this.tradeMapper = tradeMapper;
        this.notificationService = notificationService;
    }

    @Transactional
    public CouponLifecycleResult processDueCoupons() {
        int expiredMarked = markExpiredCoupons();
        LocalDate today = LocalDate.now();
        LocalDate windowEnd = today.plusDays(THREE_DAY_WINDOW);
        List<CouponRow> due = tradeMapper.selectDueCouponReminders(today, windowEnd, BATCH_SIZE);

        int threeDaySent = 0;
        int oneDaySent = 0;
        int skipped = 0;

        for (CouponRow coupon : due) {
            if (coupon.getExpireAt() == null) {
                skipped++;
                continue;
            }
            int currentStatus = coupon.getRemindStatus() == null ? 0 : coupon.getRemindStatus();
            long daysLeft = ChronoUnit.DAYS.between(today, coupon.getExpireAt());

            if (daysLeft <= ONE_DAY_WINDOW && (currentStatus & FLAG_ONE_DAY) == 0) {
                if (sendReminder(coupon, currentStatus, currentStatus | FLAG_ONE_DAY, ONE_DAY_WINDOW)) {
                    oneDaySent++;
                    currentStatus = currentStatus | FLAG_ONE_DAY;
                } else {
                    skipped++;
                    continue;
                }
            }

            if (daysLeft > ONE_DAY_WINDOW
                    && daysLeft <= THREE_DAY_WINDOW
                    && (currentStatus & FLAG_THREE_DAY) == 0) {
                if (sendReminder(coupon, currentStatus, currentStatus | FLAG_THREE_DAY, THREE_DAY_WINDOW)) {
                    threeDaySent++;
                } else {
                    skipped++;
                }
            }
        }

        if (expiredMarked > 0 || threeDaySent > 0 || oneDaySent > 0) {
            log.info(
                    "coupon lifecycle processed: expiredMarked={}, threeDayReminders={}, oneDayReminders={}, skipped={}",
                    expiredMarked,
                    threeDaySent,
                    oneDaySent,
                    skipped
            );
        }
        return new CouponLifecycleResult(expiredMarked, threeDaySent, oneDaySent, skipped);
    }

    /**
     * Best-effort sync used by coupon list reads so users do not keep seeing stale "待使用".
     */
    @Transactional
    public int expireDueCouponsForUser(Long userId) {
        if (userId == null) {
            return 0;
        }
        int marked = 0;
        List<CouponRow> expired = tradeMapper.selectExpiredActiveCoupons(BATCH_SIZE);
        for (CouponRow coupon : expired) {
            if (!userId.equals(coupon.getUserId())) {
                continue;
            }
            if (markExpired(coupon)) {
                marked++;
            }
        }
        return marked;
    }

    private int markExpiredCoupons() {
        int marked = 0;
        List<CouponRow> expired = tradeMapper.selectExpiredActiveCoupons(BATCH_SIZE);
        for (CouponRow coupon : expired) {
            if (markExpired(coupon)) {
                marked++;
            }
        }
        return marked;
    }

    private boolean markExpired(CouponRow coupon) {
        if (tradeMapper.markCouponExpired(coupon.getId()) != 1) {
            return false;
        }
        String dealTitle = blankToDefault(coupon.getDealTitle(), "团购券");
        String shopName = blankToDefault(coupon.getShopName(), "门店");
        String expireText = coupon.getExpireAt() == null ? "" : coupon.getExpireAt().format(DATE_FORMATTER);
        String content = dealTitle + " · " + shopName
                + (expireText.isBlank() ? "" : " · 有效期至 " + expireText)
                + " · 券码 " + coupon.getCode();
        String linkUrl = "/user/coupons?status=3&code=" + coupon.getCode();
        notificationService.create(
                coupon.getUserId(),
                coupon.getRegion() == null ? "CN" : coupon.getRegion(),
                EXPIRED_TYPE,
                "券码已过期",
                content,
                linkUrl
        );
        return true;
    }

    private boolean sendReminder(CouponRow coupon, int expectedStatus, int nextStatus, int windowDays) {
        if (tradeMapper.markCouponRemindStatus(coupon.getId(), expectedStatus, nextStatus) != 1) {
            return false;
        }
        String dealTitle = blankToDefault(coupon.getDealTitle(), "团购券");
        String shopName = blankToDefault(coupon.getShopName(), "门店");
        String expireText = coupon.getExpireAt() == null ? "" : coupon.getExpireAt().format(DATE_FORMATTER);
        String title = windowDays == ONE_DAY_WINDOW
                ? "券码即将过期（1 天内）"
                : "券码到期提醒（3 天内）";
        String content = dealTitle + " · " + shopName
                + (expireText.isBlank() ? "" : " · 有效期至 " + expireText)
                + " · 券码 " + coupon.getCode();
        String linkUrl = "/user/coupons?status=1&code=" + coupon.getCode() + "&remind=" + windowDays;
        notificationService.create(
                coupon.getUserId(),
                coupon.getRegion() == null ? "CN" : coupon.getRegion(),
                REMINDER_TYPE,
                title,
                content,
                linkUrl
        );
        return true;
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
