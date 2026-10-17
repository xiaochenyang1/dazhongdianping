package com.tuowei.dazhongdianping.module.reservation.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.reservation.mapper.ReservationMapper;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationLogRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationShopRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationSlotRow;
import com.tuowei.dazhongdianping.module.reservation.model.request.ReservationCreateRequest;
import com.tuowei.dazhongdianping.module.reservation.model.request.ReservationRescheduleRequest;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReservationService {
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private final ReservationMapper mapper;
    private final NotificationService notificationService;
    private final ReservationAvailabilityService availability;
    private final ReservationTimeService time;

    public ReservationService(ReservationMapper mapper, NotificationService notificationService,
                              ReservationAvailabilityService availability, ReservationTimeService time) {
        this.mapper = mapper;
        this.notificationService = notificationService;
        this.availability = availability;
        this.time = time;
    }

    public Map<String, Object> slots(Long shopId, LocalDate date, Integer people) {
        if (people == null || people < 1) throw new IllegalArgumentException("peopleCount 必须大于 0");
        ReservationShopRow shop = availability.requireAvailable(shopId, region());
        LocalDate today = time.today(shop.getTimeZone());
        LocalDate selectedDate = date == null ? today.plusDays(1) : date;
        List<Map<String, Object>> slots = mapper.selectSlots(shopId, region(), selectedDate).stream()
                .map(slot -> slotMap(slot, people, shop.getTimeZone())).toList();
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("shop", Map.of("id", shopId, "name", shop.getName()));
        result.put("date", selectedDate);
        result.put("today", today);
        result.put("timeZone", shop.getTimeZone());
        result.put("list", slots);
        return result;
    }

    @Transactional
    public Map<String, Object> create(ReservationCreateRequest request) {
        UserSession user = user();
        ReservationShopRow shop = availability.lockAvailable(request.shopId(), region());
        ReservationSlotRow slot = resolveSlot(request.slotId(), request.shopId(), request.reserveTime());
        LocalDateTime reserveTime = slotTime(slot, request.reserveTime());
        time.requireFuture(reserveTime, shop.getTimeZone());
        if (slot != null && mapper.reserveCapacity(slot.getId(), request.peopleCount()) == 0) {
            throw new IllegalArgumentException("当前时段余量不足");
        }
        ReservationRow row = new ReservationRow();
        row.setReservationNo("RS" + UUID.randomUUID().toString().replace("-", "").substring(0, 30));
        row.setUserId(user.userId());
        row.setShopId(request.shopId());
        row.setSlotId(slot == null ? 0L : slot.getId());
        row.setRegion(region());
        row.setReserveTime(reserveTime);
        row.setTimeZone(shop.getTimeZone());
        row.setPeopleCount(request.peopleCount());
        row.setContactName(request.contactName().trim());
        row.setContactPhone(request.contactPhone().trim());
        row.setRemark(request.remark() == null ? "" : request.remark().trim());
        row.setStatus(slot != null && slot.getConfirmMode() == 1 ? 1 : 0);
        mapper.insertReservation(row);
        log(row.getId(), 1, 0, row.getStatus(), null, reserveTime, "创建预订", user.userId());
        ReservationRow created = require(row.getId());
        notifyReservationCreated(created);
        return map(created, false);
    }

    public PageResult<Map<String, Object>> list(Integer status, Integer page, Integer pageSize) {
        int p = page == null ? 1 : Math.max(1, page);
        int size = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        UserSession user = user();
        long total = mapper.countUserReservations(user.userId(), region(), status);
        List<Map<String, Object>> list = mapper.selectUserReservations(
                user.userId(), region(), status, size, (p - 1) * size).stream().map(row -> map(row, false)).toList();
        return new PageResult<>(list, total, p, size, (p - 1) * size + list.size() < total);
    }

    public Map<String, Object> detail(Long id) {
        return map(require(id), true);
    }

    @Transactional
    public Map<String, Object> cancel(Long id) {
        ReservationRow row = require(id);
        if (!time.canCancel(row)) throw new IllegalArgumentException("已超过允许取消时间");
        if (mapper.cancelReservation(id, row.getUserId()) == 0) {
            throw new IllegalArgumentException("预订当前不可取消");
        }
        releaseCapacity(row);
        log(id, 4, row.getStatus(), 3, row.getReserveTime(), row.getReserveTime(), "用户取消", row.getUserId());
        return map(require(id), true);
    }

    @Transactional
    public Map<String, Object> reschedule(Long id, ReservationRescheduleRequest request) {
        ReservationRow row = require(id);
        ReservationShopRow shop = availability.lockAvailable(row.getShopId(), region());
        if (!time.canReschedule(row)) throw new IllegalArgumentException("预订当前不可改期");
        ReservationSlotRow slot = resolveSlot(request.slotId(), row.getShopId(), request.reserveTime());
        LocalDateTime next = slotTime(slot, request.reserveTime());
        time.requireFuture(next, shop.getTimeZone());
        int nextStatus = slot != null && slot.getConfirmMode() == 1 ? 1 : 0;
        if (slot != null && mapper.reserveCapacity(slot.getId(), row.getPeopleCount()) == 0) {
            throw new IllegalArgumentException("新时段余量不足");
        }
        if (mapper.rescheduleReservation(id, row.getUserId(), slot == null ? 0L : slot.getId(),
                next, shop.getTimeZone(), nextStatus) == 0) {
            throw new IllegalArgumentException("预订当前不可改期");
        }
        releaseCapacity(row);
        log(id, 5, row.getStatus(), nextStatus, row.getReserveTime(), next, request.reason().trim(), row.getUserId());
        return map(require(id), true);
    }

    private ReservationSlotRow resolveSlot(Long slotId, Long shopId, LocalDateTime reserveTime) {
        if (slotId == null) {
            if (reserveTime == null) throw new IllegalArgumentException("slotId 与 reserveTime 至少传一个");
            return null;
        }
        ReservationSlotRow slot = mapper.selectSlot(slotId, shopId, region());
        if (slot == null) throw new NotFoundException("预订时段不存在");
        return slot;
    }

    private LocalDateTime slotTime(ReservationSlotRow slot, LocalDateTime requested) {
        return slot == null ? requested : LocalDateTime.of(slot.getBizDate(), slot.getStartTime());
    }

    private void releaseCapacity(ReservationRow row) {
        if (row.getSlotId() != null && row.getSlotId() > 0) {
            mapper.releaseCapacity(row.getSlotId(), row.getPeopleCount());
        }
    }

    private ReservationRow require(Long id) {
        ReservationRow row = mapper.selectUserReservation(id, user().userId(), region());
        if (row == null) throw new NotFoundException("预订不存在");
        return row;
    }

    private UserSession user() {
        UserSession user = UserSessionContext.get();
        if (user == null) throw new UnauthorizedException("用户登录状态不存在");
        return user;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private Map<String, Object> slotMap(ReservationSlotRow slot, int people, String timeZone) {
        int remaining = Math.max(0, slot.getCapacity() - slot.getReservedCount());
        boolean future;
        try {
            future = time.requireUnambiguous(slotTime(slot, null), timeZone).isAfter(time.now());
        } catch (IllegalArgumentException exception) {
            future = false;
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("slotId", slot.getId());
        result.put("startTime", slot.getStartTime());
        result.put("endTime", slot.getEndTime());
        result.put("capacity", slot.getCapacity());
        result.put("remainingCount", remaining);
        result.put("confirmMode", slot.getConfirmMode());
        result.put("confirmModeText", slot.getConfirmMode() == 1 ? "自动确认" : "人工确认");
        result.put("cancelBeforeMinutes", slot.getCancelBeforeMinutes());
        result.put("available", future && remaining >= people);
        result.put("closedReason", !future ? "该时间不可预订" : remaining >= people ? "" : "余量不足");
        return result;
    }

    private Map<String, Object> map(ReservationRow row, boolean timeline) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("reservationNo", row.getReservationNo());
        result.put("shop", Map.of("id", row.getShopId(), "name", row.getShopName(),
                "coverImage", row.getCoverImage(), "address", row.getAddress()));
        result.put("slotId", row.getSlotId());
        result.put("reserveTime", row.getReserveTime());
        result.put("timeZone", row.getTimeZone());
        result.put("reserveAt", time.reservationInstant(row));
        result.put("today", time.today(row.getTimeZone()));
        result.put("peopleCount", row.getPeopleCount());
        result.put("contactName", row.getContactName());
        result.put("contactPhone", row.getContactPhone());
        result.put("remark", row.getRemark());
        result.put("status", row.getStatus());
        result.put("statusText", statusText(row.getStatus()));
        result.put("confirmMode", row.getConfirmMode());
        result.put("confirmModeText", Integer.valueOf(1).equals(row.getConfirmMode()) ? "自动确认" : "人工确认");
        result.put("rescheduleCount", row.getRescheduleCount());
        result.put("canCancel", time.canCancel(row));
        result.put("canReschedule", time.canReschedule(row));
        if (timeline) result.put("timeline", mapper.selectLogs(row.getId()).stream().map(this::logMap).toList());
        return result;
    }

    private void notifyReservationCreated(ReservationRow row) {
        String shopName = row.getShopName() == null || row.getShopName().isBlank() ? "门店" : row.getShopName();
        boolean confirmed = row.getStatus() == 1;
        String content = shopName + " · " + row.getReserveTime().format(TIME_FORMATTER) + " " + row.getTimeZone()
                + " · " + row.getPeopleCount() + " 人 · " + (confirmed ? "系统已自动确认你的预订" : "已提交，等待商户确认");
        notificationService.create(row.getUserId(), row.getRegion(), "reservation.created",
                confirmed ? "预订已自动确认" : "预订已提交", content,
                "/user/reservations/" + row.getId() + "?status=" + (confirmed ? "confirmed" : "pending"));
    }

    private void log(Long id, int action, int from, int to, LocalDateTime oldTime,
                     LocalDateTime newTime, String remark, Long userId) {
        ReservationLogRow row = new ReservationLogRow();
        row.setReservationId(id);
        row.setActionType(action);
        row.setOperatorType(1);
        row.setOperatorId(userId);
        row.setFromStatus(from);
        row.setToStatus(to);
        row.setOldReserveTime(oldTime);
        row.setNewReserveTime(newTime);
        row.setRemark(remark);
        mapper.insertLog(row);
    }

    private Map<String, Object> logMap(ReservationLogRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("actionType", row.getActionType());
        result.put("actionText", actionText(row.getActionType()));
        result.put("operatorType", row.getOperatorType());
        result.put("operatorText", operatorText(row.getOperatorType()));
        result.put("remark", row.getRemark() == null ? "" : row.getRemark());
        result.put("createdAt", row.getCreatedAt());
        return result;
    }

    private String actionText(int action) {
        return switch (action) {
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

    private String operatorText(Integer type) {
        if (type == null) return "用户";
        return switch (type) {
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
}
