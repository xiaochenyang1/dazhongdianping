package com.tuowei.dazhongdianping.module.admin.trade.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.trade.mapper.AdminTradeMapper;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderQuery;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.request.AdminRefundAuditRequest;
import com.tuowei.dazhongdianping.module.admin.trade.model.response.AdminOrderResponse;
import com.tuowei.dazhongdianping.module.admin.trade.model.response.AdminTradeReconcileResponse;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import com.tuowei.dazhongdianping.module.trade.model.TradeReconcileResult;
import com.tuowei.dazhongdianping.module.trade.service.TradeCompensationService;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AdminTradeService {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminTradeMapper mapper;
    private final AdminAuditMapper adminAuditMapper;
    private final TradeCompensationService tradeCompensationService;

    public AdminTradeService(
            AdminTradeMapper mapper,
            AdminAuditMapper adminAuditMapper,
            TradeCompensationService tradeCompensationService
    ) {
        this.mapper = mapper;
        this.adminAuditMapper = adminAuditMapper;
        this.tradeCompensationService = tradeCompensationService;
    }

    public PageResult<AdminOrderResponse> listOrders(AdminOrderQuery query) {
        query.normalize();
        validateDateRange(query.getDateFrom(), query.getDateTo());
        LocalDate dateToExclusive = query.getDateTo() == null ? null : query.getDateTo().plusDays(1);
        String region = RegionContext.getRegion().name();
        long total = mapper.countOrders(region, query, dateToExclusive);
        List<AdminOrderResponse> list = mapper.selectOrders(region, query, dateToExclusive).stream()
                .map(this::toResponse)
                .toList();
        return new PageResult<>(
                list,
                total,
                query.getPage(),
                query.getPageSize(),
                query.getOffset() + list.size() < total
        );
    }

    @Transactional
    public AdminOrderResponse auditRefund(Long orderId, AdminRefundAuditRequest request, String requestIp) {
        String region = RegionContext.getRegion().name();
        AdminOrderRow order = mapper.selectOrderById(region, orderId);
        if (order == null) {
            throw new NotFoundException("订单不存在");
        }
        RefundRow refund = mapper.selectRefundByOrder(orderId);
        if (refund == null || refund.getStatus() != 0) {
            throw new IllegalArgumentException("订单没有待处理退款申请");
        }
        String decision = request.decision().trim().toLowerCase(Locale.ROOT);
        String reason = request.reason().trim();
        AdminSession admin = currentAdmin();
        String action;
        if ("approve".equals(decision)) {
            requireAffected(mapper.approveRefund(orderId, admin.adminId(), reason));
            requireAffected(mapper.markOrderRefunded(orderId));
            mapper.markCouponsRefunded(orderId);
            requireAffected(mapper.restoreDealStock(order.getDealId(), order.getQuantity()));
            action = "refund_approve";
        } else if ("reject".equals(decision)) {
            requireAffected(mapper.rejectRefund(orderId, admin.adminId(), reason));
            action = "refund_reject";
        } else {
            throw new IllegalArgumentException("退款审核决定只允许 approve 或 reject");
        }
        adminAuditMapper.insertAuditLog(
                admin.adminId(),
                action,
                "order:" + orderId,
                reason,
                StringUtils.hasText(requestIp) ? requestIp.trim() : ""
        );
        return toResponse(mapper.selectOrderById(region, orderId));
    }

    @Transactional
    public AdminTradeReconcileResponse reconcile(String requestIp) {
        AdminSession admin = currentAdmin();
        TradeReconcileResult result = tradeCompensationService.reconcile();
        adminAuditMapper.insertAuditLog(
                admin.adminId(),
                "trade_reconcile",
                "orders",
                "closedOrders=" + result.closedOrders()
                        + ",restoredStockOrders=" + result.restoredStockOrders()
                        + ",failedPayments=" + result.failedPayments(),
                StringUtils.hasText(requestIp) ? requestIp.trim() : ""
        );
        return new AdminTradeReconcileResponse(
                result.closedOrders(),
                result.restoredStockOrders(),
                result.failedPayments()
        );
    }

    private void requireAffected(int affected) {
        if (affected != 1) {
            throw new IllegalArgumentException("订单或退款状态已变化，请刷新后重试");
        }
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return session;
    }

    private AdminOrderResponse toResponse(AdminOrderRow row) {
        return new AdminOrderResponse(
                row.getId(),
                safeText(row.getOrderNo()),
                row.getMerchantId(),
                safeText(row.getMerchantName()),
                row.getShopId(),
                safeText(row.getShopName()),
                row.getUserId(),
                safeText(row.getUserNickname()),
                safeText(row.getAccount()),
                row.getDealId(),
                safeText(row.getDealTitle()),
                row.getQuantity(),
                row.getUnitPrice(),
                row.getAmount(),
                safeText(row.getCurrency()),
                safeText(row.getPayMethod()),
                row.getPayStatus(),
                payStatusText(row.getPayStatus()),
                row.getStatus(),
                orderStatusText(row.getStatus()),
                safeText(row.getPaymentChannel()),
                safeText(row.getPaymentChannelTxn()),
                row.getPaymentStatus(),
                paymentStatusText(row.getPaymentStatus()),
                formatDateTime(row.getPaidAt()),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getPaymentCreatedAt()),
                row.getRefundId(),
                row.getRefundAmount(),
                safeText(row.getRefundReason()),
                row.getRefundStatus(),
                refundStatusText(row.getRefundStatus()),
                safeText(row.getRefundAuditReason()),
                formatDateTime(row.getRefundAuditedAt()),
                formatDateTime(row.getRefundCreatedAt())
        );
    }

    private void validateDateRange(LocalDate dateFrom, LocalDate dateTo) {
        if (dateFrom != null && dateTo != null && dateFrom.isAfter(dateTo)) {
            throw new IllegalArgumentException("dateFrom 不能晚于 dateTo");
        }
        if (dateFrom != null && dateTo != null && ChronoUnit.DAYS.between(dateFrom, dateTo) >= 90) {
            throw new IllegalArgumentException("订单查询范围不能超过 90 天");
        }
    }

    private String payStatusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 1 -> "已支付";
            case 2 -> "已退款";
            case 3 -> "部分退款";
            default -> "待支付";
        };
    }

    private String orderStatusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 2 -> "已关闭";
            default -> "正常";
        };
    }

    private String paymentStatusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 1 -> "成功";
            case 2 -> "失败";
            default -> "待回调";
        };
    }

    private String refundStatusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 1 -> "退款成功";
            case 2 -> "已驳回";
            default -> "申请中";
        };
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private String safeText(String value) {
        return value == null ? "" : value;
    }
}
