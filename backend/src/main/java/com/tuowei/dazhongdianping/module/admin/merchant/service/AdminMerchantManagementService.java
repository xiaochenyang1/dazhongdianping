package com.tuowei.dazhongdianping.module.admin.merchant.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.merchant.mapper.AdminMerchantManagementMapper;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantRow;
import com.tuowei.dazhongdianping.module.admin.merchant.model.request.AdminMerchantStatusRequest;
import com.tuowei.dazhongdianping.module.admin.merchant.model.response.AdminMerchantResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AdminMerchantManagementService {

    private static final int STATUS_ACTIVE = 1;
    private static final int STATUS_DISABLED = 2;
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminMerchantManagementMapper mapper;
    private final AdminAuditMapper adminAuditMapper;

    public AdminMerchantManagementService(AdminMerchantManagementMapper mapper,
                                          AdminAuditMapper adminAuditMapper) {
        this.mapper = mapper;
        this.adminAuditMapper = adminAuditMapper;
    }

    public PageResult<AdminMerchantResponse> listMerchants(AdminMerchantQuery query) {
        query.normalize();
        String region = RegionContext.getRegion().name();
        long total = mapper.countMerchants(query, region);
        List<AdminMerchantResponse> list = mapper.selectMerchants(query, region).stream()
                .map(this::toResponse)
                .toList();
        return new PageResult<>(
                list,
                total,
                query.getPage(),
                query.getPageSize(),
                query.getOffset() + list.size() < total
        );
    }

    public AdminMerchantResponse getMerchant(Long merchantId) {
        return toResponse(requireMerchant(merchantId));
    }

    @Transactional
    public AdminMerchantResponse updateMerchantStatus(Long merchantId,
                                                      AdminMerchantStatusRequest request,
                                                      String requestIp) {
        String action = normalizeAction(request.getAction());
        String reason = StringUtils.hasText(request.getReason()) ? request.getReason().trim() : "";
        AdminMerchantRow merchant = requireMerchant(merchantId);

        if ("disable".equals(action)) {
            if (!StringUtils.hasText(reason)) {
                throw new IllegalArgumentException("停用商户必须填写原因");
            }
            changeStatus(merchant, STATUS_ACTIVE, STATUS_DISABLED);
            adminAuditMapper.insertAuditLog(
                    currentAdmin().adminId(),
                    "merchant_disable",
                    "merchant:" + merchantId,
                    reason,
                    normalizeIp(requestIp)
            );
        } else {
            changeStatus(merchant, STATUS_DISABLED, STATUS_ACTIVE);
            adminAuditMapper.insertAuditLog(
                    currentAdmin().adminId(),
                    "merchant_enable",
                    "merchant:" + merchantId,
                    reason,
                    normalizeIp(requestIp)
            );
        }
        return toResponse(requireMerchant(merchantId));
    }

    private void changeStatus(AdminMerchantRow merchant, int expectedStatus, int status) {
        if (merchant.getStatus() == null || merchant.getStatus() != expectedStatus) {
            throw new IllegalArgumentException(status == STATUS_DISABLED
                    ? "商户当前状态不允许停用"
                    : "商户当前状态不允许恢复");
        }
        if (mapper.updateMerchantStatus(
                merchant.getId(),
                RegionContext.getRegion().name(),
                expectedStatus,
                status
        ) == 0) {
            throw new IllegalArgumentException("商户状态已变更，请刷新后重试");
        }
    }

    private AdminMerchantRow requireMerchant(Long merchantId) {
        AdminMerchantRow row = mapper.selectMerchantById(merchantId, RegionContext.getRegion().name());
        if (row == null) {
            throw new NotFoundException("商户不存在");
        }
        return row;
    }

    private AdminMerchantResponse toResponse(AdminMerchantRow row) {
        int status = row.getStatus() == null ? STATUS_DISABLED : row.getStatus();
        return new AdminMerchantResponse(
                row.getId(),
                safeText(row.getAccount()),
                safeText(row.getCompanyName()),
                safeText(row.getContactName()),
                safeText(row.getContactPhone()),
                safeText(row.getRegion()),
                row.getAuditStatus(),
                auditStatusText(row.getAuditStatus()),
                status,
                status == STATUS_ACTIVE ? "正常" : "已停用",
                safeCount(row.getShopCount()),
                safeCount(row.getOperatorCount()),
                safeCount(row.getActiveOperatorCount()),
                status == STATUS_DISABLED ? latestDisableReason(row.getId()) : "",
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private String latestDisableReason(Long merchantId) {
        String reason = adminAuditMapper.selectLatestAuditLogDetail("merchant_disable", "merchant:" + merchantId);
        return reason == null ? "" : reason;
    }

    private String auditStatusText(Integer status) {
        return switch (status == null ? 0 : status) {
            case 1 -> "已通过";
            case 2 -> "已驳回";
            default -> "待审核";
        };
    }

    private String normalizeAction(String action) {
        String value = action == null ? "" : action.trim().toLowerCase(Locale.ROOT);
        return switch (value) {
            case "disable", "enable" -> value;
            default -> throw new IllegalArgumentException("action 只支持 disable 或 enable");
        };
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return session;
    }

    private long safeCount(Long value) {
        return value == null ? 0 : value;
    }

    private String safeText(String value) {
        return value == null ? "" : value;
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private String normalizeIp(String requestIp) {
        return StringUtils.hasText(requestIp) ? requestIp.trim() : "";
    }
}
