package com.tuowei.dazhongdianping.module.merchant.dashboard.mapper;

import com.tuowei.dazhongdianping.module.merchant.dashboard.model.MerchantDashboardDailyRow;
import com.tuowei.dazhongdianping.module.merchant.dashboard.model.MerchantDashboardTotalsRow;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MerchantDashboardMapper {
    MerchantDashboardTotalsRow selectTotals(
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("shopId") Long shopId,
            @Param("shopIds") List<Long> shopIds,
            @Param("dateFrom") LocalDate dateFrom,
            @Param("dateTo") LocalDate dateTo,
            @Param("startAt") LocalDateTime startAt,
            @Param("endAt") LocalDateTime endAt
    );

    List<MerchantDashboardDailyRow> selectTrend(
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("shopId") Long shopId,
            @Param("shopIds") List<Long> shopIds,
            @Param("dateFrom") LocalDate dateFrom,
            @Param("dateTo") LocalDate dateTo,
            @Param("startAt") LocalDateTime startAt,
            @Param("endAt") LocalDateTime endAt
    );
}
