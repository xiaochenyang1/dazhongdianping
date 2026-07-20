package com.tuowei.dazhongdianping.module.merchant.dashboard.service;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.dashboard.mapper.MerchantDashboardMapper;
import com.tuowei.dazhongdianping.module.merchant.dashboard.model.MerchantDashboardDailyRow;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;

@Service
public class MerchantDashboardService {
    private final MerchantDashboardMapper mapper;
    private final MerchantAuthorizationService authorizationService;

    public MerchantDashboardService(MerchantDashboardMapper mapper, MerchantAuthorizationService authorizationService) {
        this.mapper = mapper;
        this.authorizationService = authorizationService;
    }

    public Map<String,Object> dashboard(Long shopId, LocalDate dateFrom, LocalDate dateTo) {
        MerchantSession session = session();
        authorizationService.requirePermission(session,"dashboard:view");
        LocalDate end = dateTo == null ? LocalDate.now() : dateTo;
        LocalDate start = dateFrom == null ? end.minusDays(6) : dateFrom;
        if (start.isAfter(end)) throw new IllegalArgumentException("dateFrom 不能晚于 dateTo");
        if (ChronoUnit.DAYS.between(start,end) >= 90) throw new IllegalArgumentException("看板查询范围不能超过 90 天");
        if (shopId != null) authorizationService.requireShop(session,"dashboard:view",shopId);
        List<Long> shopIds = authorizationService.scopedShopIds(session);
        var totals = mapper.selectTotals(session.merchantId(), RegionContext.getRegion().name(), shopId, shopIds,
                start,end,start.atStartOfDay(),end.plusDays(1).atStartOfDay());
        Map<LocalDate,MerchantDashboardDailyRow> rows = mapper.selectTrend(session.merchantId(),RegionContext.getRegion().name(),shopId,shopIds,
                start,end,start.atStartOfDay(),end.plusDays(1).atStartOfDay()).stream()
                .collect(Collectors.toMap(MerchantDashboardDailyRow::getBizDate, Function.identity()));
        List<Map<String,Object>> trend = start.datesUntil(end.plusDays(1)).map(date -> {
            MerchantDashboardDailyRow row=rows.get(date); Map<String,Object> item=new LinkedHashMap<>(); item.put("date",date);
            item.put("views",row==null?0:row.getViews()); item.put("paidOrders",row==null?0:row.getPaidOrders());
            item.put("verifiedCoupons",row==null?0:row.getVerifiedCoupons()); item.put("reservations",row==null?0:row.getReservations()); return item;
        }).toList();
        Map<String,Object> result=new LinkedHashMap<>(); result.put("dateFrom",start);result.put("dateTo",end);result.put("views",totals.getViews());
        result.put("paidOrders",totals.getPaidOrders());result.put("paidAmount",totals.getPaidAmount());result.put("verifiedCoupons",totals.getVerifiedCoupons());
        result.put("reservations",Map.of("total",totals.getReservationsTotal(),"pending",totals.getPendingReservations(),"confirmed",totals.getConfirmedReservations(),"arrived",totals.getArrivedReservations(),"rejected",totals.getRejectedReservations(),"noShow",totals.getNoShowReservations()));
        result.put("rating",Map.of("score",totals.getScore(),"reviewCount",totals.getReviewCount())); result.put("trend",trend); return result;
    }
    private MerchantSession session(){MerchantSession s=MerchantSessionContext.get();if(s==null)throw new UnauthorizedException("商户登录状态不存在");return s;}
}
