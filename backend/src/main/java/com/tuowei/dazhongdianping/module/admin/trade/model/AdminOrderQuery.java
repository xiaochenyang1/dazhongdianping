package com.tuowei.dazhongdianping.module.admin.trade.model;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.time.LocalDate;
import lombok.Data;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.util.StringUtils;

@Data
public class AdminOrderQuery {

    @Min(value = 1, message = "merchantId 最小为 1")
    private Long merchantId;

    @Min(value = 1, message = "shopId 最小为 1")
    private Long shopId;

    @Min(value = 1, message = "userId 最小为 1")
    private Long userId;

    private Integer payStatus;
    private Integer refundStatus;
    private String orderNo;

    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    private LocalDate dateFrom;

    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    private LocalDate dateTo;

    @Min(value = 1, message = "page 最小为 1")
    private Integer page = 1;

    @Min(value = 1, message = "pageSize 最小为 1")
    @Max(value = 50, message = "pageSize 最大为 50")
    private Integer pageSize = 20;

    public int getOffset() {
        return (page - 1) * pageSize;
    }

    public void normalize() {
        orderNo = StringUtils.hasText(orderNo) ? orderNo.trim() : null;
        if (page == null || page < 1) {
            page = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 20;
        }
        if (pageSize > 50) {
            pageSize = 50;
        }
    }
}
