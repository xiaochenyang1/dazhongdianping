package com.tuowei.dazhongdianping.module.merchant.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.reservation.mapper.ReservationMapper;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationLogRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationSlotRow;
import com.tuowei.dazhongdianping.module.reservation.model.request.ReservationRescheduleRequest;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantReservationService {

    private final ReservationMapper reservationMapper;
    private final MerchantAuthorizationService authorizationService;

    public MerchantReservationService(
            ReservationMapper reservationMapper,
            MerchantAuthorizationService authorizationService
    ) {
        this.reservationMapper = reservationMapper;
        this.authorizationService = authorizationService;
    }

    public PageResult<Map<String, Object>> list(
            Long shopId,
            Integer status,
            LocalDate dateFrom,
            LocalDate dateTo,
            Integer page,
            Integer pageSize
    ) {
        MerchantSession merchant = merchant();
        authorizationService.requirePermission(merchant, "reservation:view");
        List<Long> shopIds = authorizationService.scopedShopIds(merchant);
        if (shopIds != null && shopIds.isEmpty()) {
            return new PageResult<>(List.of(), 0, 1, 20, false);
        }
        if (shopId != null && shopIds != null && !shopIds.contains(shopId)) {
            throw new NotFoundException("门店不存在");
        }
        if (dateFrom != null && dateTo != null && dateFrom.isAfter(dateTo)) {
            throw new IllegalArgumentException("dateFrom 不能晚于 dateTo");
        }
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        long total = reservationMapper.countMerchantReservations(
                merchant.merchantId(), region(), shopIds, shopId, status, dateFrom, dateTo
        );
        List<Map<String, Object>> list = reservationMapper.selectMerchantReservations(
                merchant.merchantId(), region(), shopIds, shopId, status, dateFrom, dateTo,
                normalizedPageSize, (normalizedPage - 1) * normalizedPageSize
        ).stream().map(row -> reservationMap(row, false)).toList();
        return new PageResult<>(list, total, normalizedPage, normalizedPageSize,
                (normalizedPage - 1) * normalizedPageSize + list.size() < total);
    }

    public Map<String, Object> detail(Long reservationId) {
        MerchantSession merchant = merchant();
        authorizationService.requirePermission(merchant, "reservation:view");
        ReservationRow row = reservationMapper.selectMerchantReservation(
                reservationId, merchant.merchantId(), region()
        );
        if (row == null) {
            throw new NotFoundException("预订不存在");
        }
        List<Long> shopIds = authorizationService.scopedShopIds(merchant);
        if (shopIds != null && !shopIds.contains(row.getShopId())) {
            throw new NotFoundException("预订不存在");
        }
        return reservationMap(row, true);
    }

    @Transactional
    public Map<String, Object> reschedule(Long reservationId, ReservationRescheduleRequest request) {
        MerchantSession merchant = merchant();
        authorizationService.requirePermission(merchant, "reservation:confirm");
        ReservationRow current = reservationMapper.selectMerchantReservation(
                reservationId, merchant.merchantId(), region()
        );
        if (current == null) {
            throw new NotFoundException("预订不存在");
        }
        List<Long> shopIds = authorizationService.scopedShopIds(merchant);
        if (shopIds != null && !shopIds.contains(current.getShopId())) {
            throw new NotFoundException("预订不存在");
        }
        if (current.getStatus() != 0 && current.getStatus() != 1) {
            throw new IllegalArgumentException("预订当前状态不允许改期");
        }
        if (request.slotId() == null) {
            throw new IllegalArgumentException("商户改期必须选择门店时段");
        }
        ReservationSlotRow nextSlot = reservationMapper.selectSlot(
                request.slotId(), current.getShopId(), region()
        );
        if (nextSlot == null) {
            throw new NotFoundException("新预订时段不存在");
        }
        if (request.slotId().equals(current.getSlotId())) {
            throw new IllegalArgumentException("新时段不能与原时段相同");
        }
        if (reservationMapper.reserveCapacity(nextSlot.getId(), current.getPeopleCount()) == 0) {
            throw new IllegalArgumentException("新时段余量不足");
        }
        int nextStatus = nextSlot.getConfirmMode() == 1 ? 1 : 0;
        var nextTime = java.time.LocalDateTime.of(nextSlot.getBizDate(), nextSlot.getStartTime());
        if (reservationMapper.rescheduleMerchantReservation(
                reservationId,
                merchant.merchantId(),
                region(),
                nextSlot.getId(),
                nextTime,
                nextStatus
        ) == 0) {
            throw new IllegalArgumentException("预订状态已变化，请刷新后重试");
        }
        if (current.getSlotId() != null && current.getSlotId() > 0) {
            reservationMapper.releaseCapacity(current.getSlotId(), current.getPeopleCount());
        }
        ReservationLogRow log = new ReservationLogRow();
        log.setReservationId(reservationId);
        log.setActionType(6);
        log.setOperatorType(2);
        log.setOperatorId(merchant.operatorId());
        log.setFromStatus(current.getStatus());
        log.setToStatus(nextStatus);
        log.setOldReserveTime(current.getReserveTime());
        log.setNewReserveTime(nextTime);
        log.setRemark(request.reason().trim());
        reservationMapper.insertLog(log);
        return reservationMap(reservationMapper.selectMerchantReservation(
                reservationId, merchant.merchantId(), region()
        ), true);
    }

    private Map<String, Object> reservationMap(ReservationRow row, boolean includeTimeline) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("reservationNo", row.getReservationNo());
        result.put("shop", Map.of("id", row.getShopId(), "name", row.getShopName()));
        result.put("slotId", row.getSlotId());
        result.put("reserveTime", row.getReserveTime());
        result.put("peopleCount", row.getPeopleCount());
        result.put("contactName", row.getContactName());
        result.put("contactPhone", row.getContactPhone());
        result.put("remark", row.getRemark());
        result.put("status", row.getStatus());
        result.put("statusText", statusText(row.getStatus()));
        result.put("canConfirm", row.getStatus() == 0);
        result.put("canReject", row.getStatus() == 0);
        result.put("canReschedule", row.getStatus() == 0 || row.getStatus() == 1);
        result.put("canArrive", row.getStatus() == 1);
        result.put("canNoShow", row.getStatus() == 1);
        if (includeTimeline) {
            result.put("timeline", reservationMapper.selectLogs(row.getId()).stream()
                    .map(this::timelineMap).toList());
        }
        return result;
    }

    private Map<String, Object> timelineMap(ReservationLogRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("actionType", row.getActionType());
        result.put("operatorType", row.getOperatorType());
        result.put("operatorId", row.getOperatorId());
        result.put("fromStatus", row.getFromStatus());
        result.put("toStatus", row.getToStatus());
        result.put("remark", row.getRemark());
        result.put("createdAt", row.getCreatedAt());
        return result;
    }

    private String statusText(int status) {
        return switch (status) {
            case 1 -> "已确认";
            case 2 -> "已到店";
            case 3 -> "用户取消";
            case 4 -> "商户拒绝";
            case 5 -> "爽约";
            default -> "待确认";
        };
    }

    private MerchantSession merchant() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
