package com.tuowei.dazhongdianping.module.points.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import com.tuowei.dazhongdianping.module.points.mapper.PointsMapper;
import com.tuowei.dazhongdianping.module.points.model.PointsExchangeRow;
import com.tuowei.dazhongdianping.module.points.model.response.AdminPointsExchangeResponse;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

/** 运营侧兑换单履约：查看兑换记录、对「待发放」单发放兑换码或取消并退回积分。 */
@Service
public class AdminPointsExchangeService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final PointsMapper pointsMapper;
    private final AdminAuditLogService auditLogService;
    private final UserGrowthService userGrowthService;

    public AdminPointsExchangeService(PointsMapper pointsMapper,
                                      AdminAuditLogService auditLogService,
                                      UserGrowthService userGrowthService) {
        this.pointsMapper = pointsMapper;
        this.auditLogService = auditLogService;
        this.userGrowthService = userGrowthService;
    }

    public PageResult<AdminPointsExchangeResponse> list(Integer status, String keyword, Integer page, Integer pageSize) {
        Integer normalizedStatus = normalizeStatus(status);
        String normalizedKeyword = StringUtils.hasText(keyword) ? keyword.trim() : null;
        int currentPage = page == null || page < 1 ? 1 : page;
        int size = pageSize == null ? 20 : Math.max(1, Math.min(pageSize, 50));
        String region = region();

        long total = pointsMapper.countExchanges(region, normalizedStatus, normalizedKeyword);
        List<AdminPointsExchangeResponse> items = pointsMapper
                .selectExchanges(region, normalizedStatus, normalizedKeyword, size, (currentPage - 1) * size)
                .stream()
                .map(this::toResponse)
                .toList();
        return new PageResult<>(items, total, currentPage, size, (long) currentPage * size < total);
    }

    @Transactional
    public AdminPointsExchangeResponse fulfill(Long id, String redeemCode, String remark, String requestIp) {
        PointsExchangeRow row = require(id);
        requirePending(row);
        String code = StringUtils.hasText(redeemCode) ? redeemCode.trim() : generateRedeemCode();
        String note = StringUtils.hasText(remark) ? remark.trim() : "运营已发放";
        if (pointsMapper.markExchangeFulfilled(id, code, note) != 1) {
            throw new IllegalArgumentException("兑换单状态已变更");
        }
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.points_exchange_fulfill",
                "points_exchange:" + id,
                "userId=" + row.getUserId() + ", product=" + row.getProductName() + ", redeemCode=" + code,
                requestIp == null ? "" : requestIp
        );
        return toResponse(require(id));
    }

    @Transactional
    public AdminPointsExchangeResponse cancel(Long id, String remark, String requestIp) {
        PointsExchangeRow row = require(id);
        requirePending(row);
        String note = StringUtils.hasText(remark) ? remark.trim() : "运营取消兑换，积分已退回";
        if (pointsMapper.markExchangeCancelled(id, note) != 1) {
            throw new IllegalArgumentException("兑换单状态已变更");
        }
        pointsMapper.restoreProductStock(row.getProductId());
        userGrowthService.refundPoints(
                row.getUserId(),
                UserGrowthService.ACTION_POINTS_EXCHANGE_REFUND,
                id,
                row.getPointsCost() == null ? 0 : row.getPointsCost(),
                "取消兑换" + row.getProductName() + "退回"
        );
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.points_exchange_cancel",
                "points_exchange:" + id,
                "userId=" + row.getUserId() + ", product=" + row.getProductName()
                        + ", refundPoints=" + row.getPointsCost(),
                requestIp == null ? "" : requestIp
        );
        return toResponse(require(id));
    }

    private void requirePending(PointsExchangeRow row) {
        if (row.getStatus() == null || row.getStatus() != 0) {
            throw new IllegalArgumentException("兑换单已处理");
        }
    }

    private PointsExchangeRow require(Long id) {
        PointsExchangeRow row = pointsMapper.selectExchangeById(id, region());
        if (row == null) {
            throw new NotFoundException("兑换单不存在");
        }
        return row;
    }

    private AdminPointsExchangeResponse toResponse(PointsExchangeRow row) {
        int status = row.getStatus() == null ? 0 : row.getStatus();
        return new AdminPointsExchangeResponse(
                row.getId(),
                row.getUserId(),
                row.getUserNickname() == null ? "" : row.getUserNickname(),
                row.getProductId(),
                row.getProductName(),
                row.getRegion() == null ? "" : row.getRegion(),
                row.getPointsCost() == null ? 0 : row.getPointsCost(),
                row.getQuantity() == null ? 1 : row.getQuantity(),
                status,
                PointsMallService.exchangeStatusText(status),
                row.getRedeemCode() == null ? "" : row.getRedeemCode(),
                row.getRemark() == null ? "" : row.getRemark(),
                format(row.getFulfilledAt()),
                format(row.getCreatedAt())
        );
    }

    private Integer normalizeStatus(Integer status) {
        if (status == null) {
            return null;
        }
        if (status < 0 || status > 2) {
            throw new IllegalArgumentException("status 仅支持 0/1/2");
        }
        return status;
    }

    private String generateRedeemCode() {
        return "PT" + UUID.randomUUID().toString().replace("-", "").substring(0, 20).toUpperCase(Locale.ROOT);
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员未登录");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private String format(java.time.LocalDateTime value) {
        return value == null ? "" : value.format(FORMATTER);
    }
}
