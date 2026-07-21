package com.tuowei.dazhongdianping.module.admin.trade.service;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.trade.mapper.AdminTradeMapper;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderQuery;
import com.tuowei.dazhongdianping.module.admin.trade.model.AdminOrderRow;
import com.tuowei.dazhongdianping.module.admin.trade.model.response.AdminOrderResponse;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class AdminTradeService {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminTradeMapper mapper;

    public AdminTradeService(AdminTradeMapper mapper) {
        this.mapper = mapper;
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
