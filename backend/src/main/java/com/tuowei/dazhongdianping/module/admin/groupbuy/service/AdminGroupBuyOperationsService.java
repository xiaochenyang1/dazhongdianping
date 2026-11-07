package com.tuowei.dazhongdianping.module.admin.groupbuy.service;

import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.groupbuy.mapper.AdminGroupBuyOperationsMapper;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.AdminGroupBuySummaryRow;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.AdminGroupBuyTeamRow;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyAlertResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyReconcileResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuySummaryResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyTeamResponse;
import com.tuowei.dazhongdianping.module.marketing.service.GroupBuyOrderService;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class AdminGroupBuyOperationsService {

    private static final int SUMMARY_WINDOW_HOURS = 24;

    private final AdminGroupBuyOperationsMapper mapper;
    private final AdminAuditMapper auditMapper;
    private final GroupBuyOrderService groupBuyOrders;

    public AdminGroupBuyOperationsService(
            AdminGroupBuyOperationsMapper mapper,
            AdminAuditMapper auditMapper,
            GroupBuyOrderService groupBuyOrders) {
        this.mapper = mapper;
        this.auditMapper = auditMapper;
        this.groupBuyOrders = groupBuyOrders;
    }

    public AdminGroupBuySummaryResponse summary() {
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = scope(region);
        AdminGroupBuySummaryRow row = mapper.selectSummary(
                region, LocalDateTime.now().minusHours(SUMMARY_WINDOW_HOURS),
                scope.allCities(), scope.cityIds(), scope.shopIds());
        if (row == null) row = new AdminGroupBuySummaryRow();
        List<AdminGroupBuyAlertResponse> alerts = alerts(row);
        return new AdminGroupBuySummaryResponse(
                SUMMARY_WINDOW_HOURS,
                value(row.getTotalTeams()), value(row.getActiveTeams()), value(row.getFormedTeams()),
                value(row.getExpiredTeams()), value(row.getOverdueActiveTeams()),
                value(row.getMemberOrders()), value(row.getPaidOrders()),
                value(row.getPendingRefunds()), value(row.getFailedRefunds()),
                value(row.getMissingCouponOrders()), value(row.getUnreleasedInventoryOrders()), alerts);
    }

    public PageResult<AdminGroupBuyTeamResponse> teams(
            Integer status, boolean problemOnly, Integer page, Integer pageSize) {
        if (status != null && status != 1 && status != 2 && status != 3) {
            throw new IllegalArgumentException("status 只允许 1、2、3");
        }
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        int offset = (normalizedPage - 1) * normalizedSize;
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = scope(region);
        long total = mapper.countTeams(region, status, problemOnly,
                scope.allCities(), scope.cityIds(), scope.shopIds());
        List<AdminGroupBuyTeamResponse> list = mapper.selectTeams(
                        region, status, problemOnly, normalizedSize, offset,
                        scope.allCities(), scope.cityIds(), scope.shopIds()).stream()
                .map(this::teamResponse)
                .toList();
        return new PageResult<>(list, total, normalizedPage, normalizedSize, offset + list.size() < total);
    }

    public AdminGroupBuyReconcileResponse reconcile(Long teamId, String requestIp) {
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = scope(region);
        AdminGroupBuyTeamRow before = mapper.selectTeam(
                region, teamId, scope.allCities(), scope.cityIds(), scope.shopIds());
        if (before == null) throw new NotFoundException("拼团不存在");
        GroupBuyOrderService.TeamReconcileResult result = groupBuyOrders.reconcileTeam(teamId, region);
        AdminGroupBuyTeamRow after = mapper.selectTeam(
                region, teamId, scope.allCities(), scope.cityIds(), scope.shopIds());
        AdminSession admin = currentAdmin();
        auditMapper.insertAuditLog(
                admin.adminId(), "groupbuy_reconcile", "groupbuy_team:" + teamId,
                "status=" + result.teamStatus()
                        + ",expiredOrdersProcessed=" + result.expiredOrdersProcessed()
                        + ",vouchersIssued=" + result.vouchersIssued()
                        + ",failures=" + result.failures(),
                StringUtils.hasText(requestIp) ? requestIp.trim() : "");
        return new AdminGroupBuyReconcileResponse(
                result.teamId(), result.teamStatus(), result.expiredOrdersProcessed(),
                result.vouchersIssued(), result.failures(), teamResponse(after));
    }

    private List<AdminGroupBuyAlertResponse> alerts(AdminGroupBuySummaryRow row) {
        List<AdminGroupBuyAlertResponse> alerts = new ArrayList<>();
        addAlert(alerts, "critical", "refund_failed", value(row.getFailedRefunds()), "存在自动退款失败订单");
        addAlert(alerts, "critical", "voucher_missing", value(row.getMissingCouponOrders()), "存在已成团但未发券订单");
        addAlert(alerts, "warning", "inventory_unreleased", value(row.getUnreleasedInventoryOrders()), "存在过期团库存未释放订单");
        addAlert(alerts, "warning", "team_overdue", value(row.getOverdueActiveTeams()), "存在已到期但仍进行中的拼团");
        addAlert(alerts, "warning", "refund_pending", value(row.getPendingRefunds()), "存在等待渠道处理的自动退款");
        return alerts;
    }

    private void addAlert(List<AdminGroupBuyAlertResponse> alerts, String severity,
                          String code, long count, String message) {
        if (count > 0) alerts.add(new AdminGroupBuyAlertResponse(severity, code, count, message));
    }

    private AdminGroupBuyTeamResponse teamResponse(AdminGroupBuyTeamRow row) {
        if (row == null) throw new NotFoundException("拼团不存在");
        long pending = value(row.getPendingRefunds());
        long failed = value(row.getFailedRefunds());
        long missingCoupons = value(row.getMissingCouponOrders());
        long unreleased = value(row.getUnreleasedInventoryOrders());
        boolean overdue = Integer.valueOf(1).equals(row.getStatus())
                && row.getExpireAt() != null && !row.getExpireAt().isAfter(LocalDateTime.now());
        return new AdminGroupBuyTeamResponse(
                row.getId(), row.getCampaignId(), text(row.getCampaignTitle()),
                row.getShopId(), text(row.getShopName()), row.getCityId(), text(row.getRegion()),
                row.getStatus(), statusText(row.getStatus()), row.getMemberCount(), row.getPaidCount(),
                row.getGroupSize(), value(row.getMemberOrders()), value(row.getPaidOrders()),
                pending, failed, missingCoupons, unreleased,
                overdue || pending > 0 || failed > 0 || missingCoupons > 0 || unreleased > 0,
                row.getExpireAt(), row.getCreatedAt(), row.getUpdatedAt());
    }

    private String statusText(Integer status) {
        if (status == null) return "未知";
        return switch (status) {
            case 1 -> "进行中";
            case 2 -> "已成团";
            case 3 -> "已过期";
            default -> "未知";
        };
    }

    private AdminCityScope scope(String region) {
        AdminCityScope scope = currentAdmin().cityScopes().get(region);
        return scope == null ? new AdminCityScope(false, Set.of(), Set.of()) : scope;
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) throw new UnauthorizedException("管理员登录状态不存在");
        return session;
    }

    private long value(Long value) {
        return value == null ? 0 : value;
    }

    private String text(String value) {
        return value == null ? "" : value;
    }
}
