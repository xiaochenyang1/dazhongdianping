package com.tuowei.dazhongdianping.module.analytics.service;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.analytics.mapper.AnalyticsMapper;
import com.tuowei.dazhongdianping.module.analytics.model.DayMetricRow;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

/** 商家经营趋势：按日补齐浏览与已支付订单，无数据的日期记 0。 */
@Service
public class MerchantAnalyticsService {

    private final AnalyticsMapper mapper;
    private final MerchantAuthorizationService authorizationService;

    public MerchantAnalyticsService(AnalyticsMapper mapper, MerchantAuthorizationService authorizationService) {
        this.mapper = mapper;
        this.authorizationService = authorizationService;
    }

    public Map<String, Object> trend(Long shopId, Integer days) {
        String region = authorize(shopId);
        int window = normalizeDays(days);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("shopId", shopId);
        body.put("days", window);
        body.put("list", buckets(shopId, region, window));
        return body;
    }

    public String export(Long shopId, Integer days) {
        String region = authorize(shopId);
        int window = normalizeDays(days);
        StringBuilder csv = new StringBuilder("shopId,date,views,orders,amount");
        for (Map<String, Object> row : buckets(shopId, region, window)) {
            csv.append('\n')
                    .append(shopId).append(',')
                    .append(row.get("date")).append(',')
                    .append(row.get("views")).append(',')
                    .append(row.get("orders")).append(',')
                    .append(row.get("amount"));
        }
        return csv.toString();
    }

    private List<Map<String, Object>> buckets(Long shopId, String region, int days) {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(days - 1L);
        Map<LocalDate, Long> views = new LinkedHashMap<>();
        for (DayMetricRow row : mapper.selectViews(shopId, start, end)) {
            if (row.getBizDate() != null) {
                views.put(row.getBizDate(), row.getTotal() == null ? 0L : row.getTotal());
            }
        }
        Map<LocalDate, Long> orders = new LinkedHashMap<>();
        Map<LocalDate, BigDecimal> amounts = new LinkedHashMap<>();
        for (DayMetricRow row : mapper.selectPaidOrders(shopId, region, start, end)) {
            if (row.getBizDate() == null) {
                continue;
            }
            orders.put(row.getBizDate(), row.getTotal() == null ? 0L : row.getTotal());
            amounts.put(row.getBizDate(), money(row.getAmount()));
        }
        List<Map<String, Object>> list = new ArrayList<>();
        for (LocalDate day = start; !day.isAfter(end); day = day.plusDays(1)) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("date", day.toString());
            row.put("views", views.getOrDefault(day, 0L));
            row.put("orders", orders.getOrDefault(day, 0L));
            row.put("amount", amounts.getOrDefault(day, money(BigDecimal.ZERO)));
            list.add(row);
        }
        return list;
    }

    private String authorize(Long shopId) {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        authorizationService.requireShop(session, "analytics:view", shopId);
        return RegionContext.getRegion().name();
    }

    private int normalizeDays(Integer days) {
        int value = days == null ? 7 : days;
        if (value < 1 || value > 30) {
            throw new IllegalArgumentException("天数范围为 1 到 30");
        }
        return value;
    }

    private BigDecimal money(BigDecimal value) {
        return (value == null ? BigDecimal.ZERO : value).setScale(2, RoundingMode.HALF_UP);
    }
}
