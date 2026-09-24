package com.tuowei.dazhongdianping.module.analytics.mapper;

import com.tuowei.dazhongdianping.module.analytics.model.DayMetricRow;
import java.time.LocalDate;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AnalyticsMapper {

    List<DayMetricRow> selectViews(
            @Param("shopId") Long shopId, @Param("from") LocalDate from, @Param("to") LocalDate to);

    List<DayMetricRow> selectPaidOrders(
            @Param("shopId") Long shopId,
            @Param("region") String region,
            @Param("from") LocalDate from,
            @Param("to") LocalDate to);
}
