package com.tuowei.dazhongdianping.module.reservation.model;

import lombok.Data;

@Data
public class ReservationShopRow {
    private Long id;
    private Long merchantId;
    private String name;
    private String timeZone;
}
