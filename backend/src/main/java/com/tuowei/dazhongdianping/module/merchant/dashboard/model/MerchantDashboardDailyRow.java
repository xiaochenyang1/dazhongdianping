package com.tuowei.dazhongdianping.module.merchant.dashboard.model;

import java.time.LocalDate;
import lombok.Data;

@Data
public class MerchantDashboardDailyRow {
    private LocalDate bizDate;
    private Long views;
    private Long paidOrders;
    private Long verifiedCoupons;
    private Long reservations;
}
