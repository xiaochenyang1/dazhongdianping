package com.tuowei.dazhongdianping.module.admin.dashboard.service;

import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.dashboard.mapper.AdminDashboardMapper;
import com.tuowei.dazhongdianping.module.admin.dashboard.model.response.AdminDashboardResponse;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class AdminDashboardService {

    private static final Map<Integer, String> AUDIT_BIZ_LABELS = Map.of(
            2, "团购审核",
            3, "点评审核",
            4, "帖子审核",
            5, "门店草稿审核",
            6, "商户点评申诉",
            7, "达人认证",
            8, "用户封禁申诉"
    );

    private static final Map<Integer, String> AUDIT_PERMISSIONS = Map.of(
            2, "audit:deal:read",
            3, "audit:review:read",
            4, "audit:post:read",
            5, "audit:shop_change:read",
            6, "audit:review_appeal:read",
            7, "audit:expert_certification:read",
            8, "audit:user_appeal:read"
    );

    private final AdminDashboardMapper mapper;

    public AdminDashboardService(AdminDashboardMapper mapper) {
        this.mapper = mapper;
    }

    public AdminDashboardResponse overview() {
        AdminSession session = currentAdmin();
        String region = RegionContext.getRegion().name();
        Set<String> permissions = session.permissions();
        AdminCityScope scope = session.cityScopes().getOrDefault(
                region, new AdminCityScope(false, Set.of(), Set.of()));

        long shopCount = permissions.contains("data:shop:read")
                ? mapper.countShops(region, scope.allCities(), scope.cityIds(), scope.shopIds())
                : 0L;
        long importBatchCount = permissions.contains("data:import_batch:read") ? mapper.countImportBatches(region) : 0L;
        long paidOrderCount = permissions.contains("data:order:read")
                ? mapper.countPaidOrders(region, scope.allCities(), scope.cityIds(), scope.shopIds())
                : 0L;
        long pendingRefundCount = permissions.contains("data:order:read")
                ? mapper.countPendingRefunds(region, scope.allCities(), scope.cityIds(), scope.shopIds())
                : 0L;
        long userCount = permissions.contains("system:user:read") ? mapper.countUsers() : 0L;

        List<Integer> allowedBizTypes = new ArrayList<>();
        List<Map<String, Object>> breakdown = new ArrayList<>();
        for (Map.Entry<Integer, String> entry : AUDIT_PERMISSIONS.entrySet()) {
            if (!permissions.contains(entry.getValue())) {
                continue;
            }
            Integer bizType = entry.getKey();
            allowedBizTypes.add(bizType);
            long count = mapper.countPendingAuditTasks(region, List.of(bizType));
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("bizType", bizType);
            item.put("label", AUDIT_BIZ_LABELS.getOrDefault(bizType, "审核任务"));
            item.put("count", count);
            breakdown.add(item);
        }
        long pendingAuditTaskCount = allowedBizTypes.isEmpty()
                ? 0L
                : mapper.countPendingAuditTasks(region, allowedBizTypes);

        return new AdminDashboardResponse(
                region,
                shopCount,
                importBatchCount,
                paidOrderCount,
                pendingRefundCount,
                pendingAuditTaskCount,
                userCount,
                breakdown
        );
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return session;
    }
}
