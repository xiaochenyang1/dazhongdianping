package com.tuowei.dazhongdianping.module.merchant.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.reservation.mapper.ReservationMapper;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationLogRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.CouponRow;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantFulfillmentService {

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final String RESERVATION_STATUS_TYPE = "reservation.status";
    private static final String COUPON_VERIFIED_TYPE = "coupon.verified";

    private final ReservationMapper reservationMapper;
    private final TradeMapper tradeMapper;
    private final MerchantAuthorizationService authorizationService;
    private final NotificationService notificationService;

    public MerchantFulfillmentService(
            ReservationMapper reservationMapper,
            TradeMapper tradeMapper,
            MerchantAuthorizationService authorizationService,
            NotificationService notificationService
    ) {
        this.reservationMapper = reservationMapper;
        this.tradeMapper = tradeMapper;
        this.authorizationService = authorizationService;
        this.notificationService = notificationService;
    }

    @Transactional
    public Map<String, Object> confirm(Long reservationId) {
        return changeReservationStatus(reservationId, 0, 1, 2, "商户确认", false, "reservation:confirm");
    }

    @Transactional
    public Map<String, Object> reject(Long reservationId, String reason) {
        return changeReservationStatus(reservationId, 0, 4, 3, reason.trim(), true, "reservation:confirm");
    }

    @Transactional
    public Map<String, Object> arrive(Long reservationId) {
        return changeReservationStatus(reservationId, 1, 2, 7, "确认到店", false, "reservation:arrive");
    }

    @Transactional
    public Map<String, Object> noShow(Long reservationId) {
        return changeReservationStatus(reservationId, 1, 5, 8, "标记爽约", true, "reservation:arrive");
    }

    @Transactional
    public Map<String, Object> verifyCoupon(String code) {
        MerchantSession merchant = merchant();
        String normalizedCode = code.trim();
        CouponRow coupon = tradeMapper.selectMerchantCoupon(normalizedCode, merchant.merchantId(), region());
        if (coupon == null) {
            throw new NotFoundException("券码不存在");
        }
        authorizationService.requireShop(merchant, "coupon:verify", coupon.getShopId());
        if (coupon.getStatus() != 1) {
            throw new IllegalArgumentException("券码当前不可核销");
        }
        if (coupon.getExpireAt() != null && coupon.getExpireAt().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("券码已过期");
        }
        if (tradeMapper.verifyMerchantCoupon(
                normalizedCode, merchant.merchantId(), merchant.operatorId(), region()
        ) == 0) {
            throw new IllegalArgumentException("券码当前不可核销");
        }
        CouponRow verified = tradeMapper.selectMerchantCoupon(normalizedCode, merchant.merchantId(), region());
        notifyCouponVerified(verified);
        return couponMap(verified);
    }

    private void notifyCouponVerified(CouponRow coupon) {
        if (coupon == null || coupon.getUserId() == null) {
            return;
        }
        String dealTitle = blankToDefault(coupon.getDealTitle(), "团购券");
        String shopName = blankToDefault(coupon.getShopName(), "门店");
        String content = dealTitle + " · " + shopName + " · 券码 " + coupon.getCode() + " 已核销成功";
        String linkUrl = "/user/coupons/" + coupon.getCode();
        String region = coupon.getRegion() == null || coupon.getRegion().isBlank()
                ? RegionContext.getRegion().name()
                : coupon.getRegion();
        notificationService.create(
                coupon.getUserId(),
                region,
                COUPON_VERIFIED_TYPE,
                "券码已核销",
                content,
                linkUrl
        );
    }

    private Map<String, Object> changeReservationStatus(
            Long reservationId,
            int fromStatus,
            int toStatus,
            int actionType,
            String remark,
            boolean releaseCapacity,
            String permission
    ) {
        MerchantSession merchant = merchant();
        ReservationRow reservation = reservationMapper.selectMerchantReservation(
                reservationId,
                merchant.merchantId(),
                region()
        );
        if (reservation == null) {
            throw new NotFoundException("预订不存在");
        }
        authorizationService.requireShop(merchant, permission, reservation.getShopId());
        if (reservation.getStatus() != fromStatus) {
            throw new IllegalArgumentException("预订当前状态不允许此操作");
        }
        if (reservationMapper.updateMerchantStatus(
                reservationId,
                merchant.merchantId(),
                region(),
                fromStatus,
                toStatus
        ) == 0) {
            throw new IllegalArgumentException("预订状态已变化，请刷新后重试");
        }
        if (releaseCapacity && reservation.getSlotId() != null && reservation.getSlotId() > 0) {
            reservationMapper.releaseCapacity(reservation.getSlotId(), reservation.getPeopleCount());
        }
        insertReservationLog(reservation, merchant.operatorId(), actionType, fromStatus, toStatus, remark);
        ReservationRow updated = reservationMapper.selectMerchantReservation(
                reservationId,
                merchant.merchantId(),
                region()
        );
        notifyReservationStatus(updated == null ? reservation : updated, toStatus, remark);
        return reservationMap(updated);
    }

    private void notifyReservationStatus(ReservationRow reservation, int toStatus, String remark) {
        if (reservation == null || reservation.getUserId() == null) {
            return;
        }
        String shopName = blankToDefault(reservation.getShopName(), "门店");
        String reserveTimeText = reservation.getReserveTime() == null
                ? ""
                : reservation.getReserveTime().format(TIME_FORMATTER);
        String peopleText = reservation.getPeopleCount() == null ? "" : reservation.getPeopleCount() + " 人";
        String title = switch (toStatus) {
            case 1 -> "预订已确认";
            case 2 -> "已确认到店";
            case 4 -> "预订被拒绝";
            case 5 -> "预订已标记爽约";
            default -> "预订状态更新";
        };
        String actionText = switch (toStatus) {
            case 1 -> "商户已确认你的预订";
            case 2 -> "商户已确认你到店";
            case 4 -> "商户已拒绝你的预订";
            case 5 -> "商户已将本次预订标记为爽约";
            default -> "预订状态已更新";
        };
        String content = shopName
                + (reserveTimeText.isBlank() ? "" : " · " + reserveTimeText)
                + (peopleText.isBlank() ? "" : " · " + peopleText)
                + " · " + actionText
                + (remark == null || remark.isBlank() || "商户确认".equals(remark) || "确认到店".equals(remark) || "标记爽约".equals(remark)
                    ? ""
                    : "：" + remark);
        String statusQuery = switch (toStatus) {
            case 1 -> "confirmed";
            case 2 -> "arrived";
            case 4 -> "rejected";
            case 5 -> "no_show";
            default -> "updated";
        };
        String linkUrl = "/user/reservations/" + reservation.getId() + "?status=" + statusQuery;
        String region = reservation.getRegion() == null || reservation.getRegion().isBlank()
                ? RegionContext.getRegion().name()
                : reservation.getRegion();
        notificationService.create(
                reservation.getUserId(),
                region,
                RESERVATION_STATUS_TYPE,
                title,
                content,
                linkUrl
        );
    }

    private static String blankToDefault(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private void insertReservationLog(
            ReservationRow reservation,
            Long merchantId,
            int actionType,
            int fromStatus,
            int toStatus,
            String remark
    ) {
        ReservationLogRow log = new ReservationLogRow();
        log.setReservationId(reservation.getId());
        log.setActionType(actionType);
        log.setOperatorType(2);
        log.setOperatorId(merchantId);
        log.setFromStatus(fromStatus);
        log.setToStatus(toStatus);
        log.setOldReserveTime(reservation.getReserveTime());
        log.setNewReserveTime(reservation.getReserveTime());
        log.setRemark(remark);
        reservationMapper.insertLog(log);
    }

    private Map<String, Object> reservationMap(ReservationRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("reservationNo", row.getReservationNo());
        result.put("shopId", row.getShopId());
        result.put("shopName", row.getShopName());
        result.put("reserveTime", row.getReserveTime());
        result.put("peopleCount", row.getPeopleCount());
        result.put("status", row.getStatus());
        result.put("statusText", reservationStatusText(row.getStatus()));
        return result;
    }

    private Map<String, Object> couponMap(CouponRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("code", row.getCode());
        result.put("dealId", row.getDealId());
        result.put("dealTitle", row.getDealTitle());
        result.put("shopId", row.getShopId());
        result.put("shopName", row.getShopName());
        result.put("status", row.getStatus());
        result.put("statusText", couponStatusText(row.getStatus()));
        result.put("verifyAt", row.getVerifyAt());
        result.put("verifyBy", row.getVerifyBy());
        result.put("expireAt", row.getExpireAt());
        return result;
    }

    private String couponStatusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 2 -> "已使用";
            case 3 -> "已过期";
            case 4 -> "已退款";
            default -> "待使用";
        };
    }

    private String reservationStatusText(int status) {
        return switch (status) {
            case 1 -> "已确认";
            case 2 -> "已到店";
            case 4 -> "商户拒绝";
            case 5 -> "爽约";
            default -> "待确认";
        };
    }

    private MerchantSession merchant() {
        MerchantSession merchant = MerchantSessionContext.get();
        if (merchant == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return merchant;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
