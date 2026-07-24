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
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantSlotSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantSlotStatusRequest;
import com.tuowei.dazhongdianping.module.reservation.model.request.ReservationRescheduleRequest;
import java.time.LocalTime;
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


    public PageResult<Map<String, Object>> listSlots(
            Long shopId,
            LocalDate dateFrom,
            LocalDate dateTo,
            Boolean enabled,
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
        long total = reservationMapper.countMerchantSlots(
                merchant.merchantId(), region(), shopIds, shopId, dateFrom, dateTo, enabled
        );
        List<Map<String, Object>> list = reservationMapper.selectMerchantSlots(
                merchant.merchantId(), region(), shopIds, shopId, dateFrom, dateTo, enabled,
                normalizedPageSize, (normalizedPage - 1) * normalizedPageSize
        ).stream().map(this::slotMap).toList();
        return new PageResult<>(list, total, normalizedPage, normalizedPageSize,
                (normalizedPage - 1L) * normalizedPageSize + list.size() < total);
    }

    @Transactional
    public Map<String, Object> createSlot(MerchantSlotSaveRequest request) {
        MerchantSession merchant = merchant();
        authorizationService.requirePermission(merchant, "reservation:confirm");
        validateSlotRequest(request);
        ensureShopWritable(merchant, request.shopId());
        ReservationSlotRow row = new ReservationSlotRow();
        row.setShopId(request.shopId());
        row.setRegion(region());
        row.setBizDate(request.bizDate());
        row.setStartTime(request.startTime());
        row.setEndTime(request.endTime());
        row.setCapacity(request.capacity());
        row.setReservedCount(0);
        row.setConfirmMode(request.confirmMode());
        row.setCancelBeforeMinutes(request.cancelBeforeMinutes());
        row.setEnabled(request.enabled() == null || request.enabled());
        reservationMapper.insertSlot(row);
        ReservationSlotRow stored = reservationMapper.selectMerchantSlot(row.getId(), merchant.merchantId(), region());
        if (stored == null) {
            throw new IllegalStateException("时段创建失败");
        }
        return slotMap(stored);
    }

    @Transactional
    public Map<String, Object> updateSlot(Long slotId, MerchantSlotSaveRequest request) {
        MerchantSession merchant = merchant();
        authorizationService.requirePermission(merchant, "reservation:confirm");
        validateSlotRequest(request);
        ReservationSlotRow existing = reservationMapper.selectMerchantSlot(slotId, merchant.merchantId(), region());
        if (existing == null) {
            throw new NotFoundException("时段不存在");
        }
        ensureShopWritable(merchant, existing.getShopId());
        if (!existing.getShopId().equals(request.shopId())) {
            throw new IllegalArgumentException("时段所属门店不可修改");
        }
        if (request.capacity() < (existing.getReservedCount() == null ? 0 : existing.getReservedCount())) {
            throw new IllegalArgumentException("容量不能小于已占用人数");
        }
        ReservationSlotRow row = new ReservationSlotRow();
        row.setId(slotId);
        row.setShopId(existing.getShopId());
        row.setRegion(region());
        row.setBizDate(request.bizDate());
        row.setStartTime(request.startTime());
        row.setEndTime(request.endTime());
        row.setCapacity(request.capacity());
        row.setConfirmMode(request.confirmMode());
        row.setCancelBeforeMinutes(request.cancelBeforeMinutes());
        row.setEnabled(request.enabled() == null ? existing.getEnabled() : request.enabled());
        if (reservationMapper.updateSlot(row) != 1) {
            throw new IllegalArgumentException("时段更新失败，请检查容量与占用");
        }
        return slotMap(reservationMapper.selectMerchantSlot(slotId, merchant.merchantId(), region()));
    }

    @Transactional
    public Map<String, Object> updateSlotEnabled(Long slotId, MerchantSlotStatusRequest request) {
        MerchantSession merchant = merchant();
        authorizationService.requirePermission(merchant, "reservation:confirm");
        ReservationSlotRow existing = reservationMapper.selectMerchantSlot(slotId, merchant.merchantId(), region());
        if (existing == null) {
            throw new NotFoundException("时段不存在");
        }
        ensureShopWritable(merchant, existing.getShopId());
        if (reservationMapper.updateSlotEnabled(slotId, merchant.merchantId(), region(), request.enabled()) != 1) {
            throw new NotFoundException("时段不存在");
        }
        return slotMap(reservationMapper.selectMerchantSlot(slotId, merchant.merchantId(), region()));
    }

    private void validateSlotRequest(MerchantSlotSaveRequest request) {
        if (request.endTime().isBefore(request.startTime()) || request.endTime().equals(request.startTime())) {
            throw new IllegalArgumentException("结束时间必须晚于开始时间");
        }
        if (request.bizDate().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("不能配置过去日期的时段");
        }
    }

    private void ensureShopWritable(MerchantSession merchant, Long shopId) {
        if (shopId == null || shopId <= 0) {
            throw new IllegalArgumentException("shopId 无效");
        }
        List<Long> shopIds = authorizationService.scopedShopIds(merchant);
        if (shopIds != null && !shopIds.contains(shopId)) {
            throw new NotFoundException("门店不存在");
        }
        if (reservationMapper.countOwnedShop(merchant.merchantId(), region(), shopId) == 0) {
            throw new NotFoundException("门店不存在");
        }
    }

    private Map<String, Object> slotMap(ReservationSlotRow row) {
        int reserved = row.getReservedCount() == null ? 0 : row.getReservedCount();
        int capacity = row.getCapacity() == null ? 0 : row.getCapacity();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("shopId", row.getShopId());
        result.put("shopName", row.getShopName());
        result.put("bizDate", row.getBizDate());
        result.put("startTime", row.getStartTime());
        result.put("endTime", row.getEndTime());
        result.put("capacity", capacity);
        result.put("reservedCount", reserved);
        result.put("remainingCount", Math.max(0, capacity - reserved));
        result.put("confirmMode", row.getConfirmMode());
        result.put("confirmModeText", row.getConfirmMode() != null && row.getConfirmMode() == 1 ? "自动确认" : "人工确认");
        result.put("cancelBeforeMinutes", row.getCancelBeforeMinutes());
        result.put("enabled", Boolean.TRUE.equals(row.getEnabled()));
        return result;
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
        result.put("actionText", actionText(row.getActionType()));
        result.put("operatorType", row.getOperatorType());
        result.put("operatorText", operatorText(row.getOperatorType()));
        result.put("operatorId", row.getOperatorId());
        result.put("fromStatus", row.getFromStatus());
        result.put("toStatus", row.getToStatus());
        result.put("remark", row.getRemark() == null ? "" : row.getRemark());
        result.put("createdAt", row.getCreatedAt());
        return result;
    }

    private String actionText(Integer actionType) {
        if (actionType == null) {
            return "创建预订";
        }
        return switch (actionType) {
            case 2 -> "商户确认";
            case 3 -> "商户拒绝";
            case 4 -> "用户取消";
            case 5 -> "用户改期";
            case 6 -> "商户改期";
            case 7 -> "确认到店";
            case 8 -> "标记爽约";
            case 9 -> "到店提醒";
            default -> "创建预订";
        };
    }

    private String operatorText(Integer operatorType) {
        if (operatorType == null) {
            return "用户";
        }
        return switch (operatorType) {
            case 2 -> "商户";
            case 3 -> "系统";
            default -> "用户";
        };
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
