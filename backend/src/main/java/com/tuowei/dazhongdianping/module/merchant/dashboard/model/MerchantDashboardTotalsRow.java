package com.tuowei.dazhongdianping.module.merchant.dashboard.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class MerchantDashboardTotalsRow {
    private Long views;
    private Long paidOrders;
    private BigDecimal paidAmount;
    private Long verifiedCoupons;
    private Long reservationsTotal;
    private Long pendingReservations;
    private Long confirmedReservations;
    private Long arrivedReservations;
    private Long rejectedReservations;
    private Long noShowReservations;
    private BigDecimal score;
    private Long reviewCount;
}
