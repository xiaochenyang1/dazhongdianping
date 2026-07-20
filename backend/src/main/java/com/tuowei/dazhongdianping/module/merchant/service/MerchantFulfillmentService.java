package com.tuowei.dazhongdianping.module.merchant.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.reservation.mapper.ReservationMapper;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationLogRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.CouponRow;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantFulfillmentService {

    private final ReservationMapper reservationMapper;
    private final TradeMapper tradeMapper;
    private final MerchantAuthorizationService authorizationService;

    public MerchantFulfillmentService(
            ReservationMapper reservationMapper,
            TradeMapper tradeMapper,
            MerchantAuthorizationService authorizationService
    ) {
        this.reservationMapper = reservationMapper;
        this.tradeMapper = tradeMapper;
        this.authorizationService = authorizationService;
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
        return couponMap(tradeMapper.selectMerchantCoupon(normalizedCode, merchant.merchantId(), region()));
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
        return reservationMap(reservationMapper.selectMerchantReservation(
                reservationId,
                merchant.merchantId(),
                region()
        ));
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
        result.put("verifyAt", row.getVerifyAt());
        result.put("verifyBy", row.getVerifyBy());
        result.put("expireAt", row.getExpireAt());
        return result;
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
