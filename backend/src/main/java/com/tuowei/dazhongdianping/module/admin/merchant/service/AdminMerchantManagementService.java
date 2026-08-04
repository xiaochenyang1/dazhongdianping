package com.tuowei.dazhongdianping.module.admin.merchant.service;

import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
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
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperatorQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperatorRow;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperationLogQuery;
import com.tuowei.dazhongdianping.module.admin.merchant.model.AdminMerchantOperationLogRow;
import com.tuowei.dazhongdianping.module.admin.merchant.model.request.AdminMerchantStatusRequest;
import com.tuowei.dazhongdianping.module.admin.merchant.model.response.AdminMerchantResponse;
import com.tuowei.dazhongdianping.module.admin.merchant.model.response.AdminMerchantOperatorResponse;
import com.tuowei.dazhongdianping.module.admin.merchant.model.response.AdminMerchantOperationLogResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Set;
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
        AdminCityScope scope = currentScope(region);
        long total = mapper.countMerchants(query, region, scope.allCities(), scope.cityIds(), scope.shopIds());
        List<AdminMerchantResponse> list = mapper.selectMerchants(
                        query, region, scope.allCities(), scope.cityIds(), scope.shopIds())
                .stream()
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

    public PageResult<AdminMerchantOperatorResponse> listMerchantOperators(
            Long merchantId,
            AdminMerchantOperatorQuery query
    ) {
        requireMerchant(merchantId);
        query.normalize();
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = currentScope(region);
        long total = mapper.countMerchantOperators(
                merchantId, region, query, scope.allCities(), scope.cityIds(), scope.shopIds());
        List<AdminMerchantOperatorResponse> list = mapper.selectMerchantOperators(
                        merchantId, region, query, scope.allCities(), scope.cityIds(), scope.shopIds())
                .stream()
                .map(this::toOperatorResponse)
                .toList();
        return new PageResult<>(
                list,
                total,
                query.getPage(),
                query.getPageSize(),
                query.getOffset() + list.size() < total
        );
    }

    public AdminMerchantOperatorResponse getMerchantOperator(Long merchantId, Long operatorId) {
        requireMerchant(merchantId);
        return toOperatorResponse(requireMerchantOperator(merchantId, operatorId));
    }

    public PageResult<AdminMerchantOperationLogResponse> listMerchantOperationLogs(
            Long merchantId,
            AdminMerchantOperationLogQuery query
    ) {
        requireMerchant(merchantId);
        query.normalize();
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = currentScope(region);
        long total = mapper.countMerchantOperationLogs(
                merchantId, region, query, scope.allCities(), scope.cityIds(), scope.shopIds());
        List<AdminMerchantOperationLogResponse> list = mapper.selectMerchantOperationLogs(
                        merchantId, region, query, scope.allCities(), scope.cityIds(), scope.shopIds())
                .stream()
                .map(this::toOperationLogResponse)
                .toList();
        return new PageResult<>(
                list,
                total,
                query.getPage(),
                query.getPageSize(),
                query.getOffset() + list.size() < total
        );
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

    @Transactional
    public AdminMerchantOperatorResponse updateMerchantOperatorStatus(
            Long merchantId,
            Long operatorId,
            AdminMerchantStatusRequest request,
            String requestIp
    ) {
        requireMerchant(merchantId);
        String action = normalizeAction(request.getAction());
        String reason = StringUtils.hasText(request.getReason()) ? request.getReason().trim() : "";
        AdminMerchantOperatorRow operator = requireMerchantOperator(merchantId, operatorId);
        int expectedStatus = "disable".equals(action) ? STATUS_ACTIVE : STATUS_DISABLED;
        int nextStatus = "disable".equals(action) ? STATUS_DISABLED : STATUS_ACTIVE;

        if (nextStatus == STATUS_DISABLED && !StringUtils.hasText(reason)) {
            throw new IllegalArgumentException("停用商户员工必须填写原因");
        }
        if (operator.getStatus() == null || operator.getStatus() != expectedStatus) {
            throw new IllegalArgumentException(nextStatus == STATUS_DISABLED
                    ? "商户员工当前状态不允许停用"
                    : "商户员工当前状态不允许恢复");
        }
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = currentScope(region);
        if (mapper.updateMerchantOperatorStatus(
                merchantId,
                operatorId,
                region,
                expectedStatus,
                nextStatus,
                scope.allCities(),
                scope.cityIds(),
                scope.shopIds()
        ) == 0) {
            throw new IllegalArgumentException("商户员工状态已变更，请刷新后重试");
        }

        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                nextStatus == STATUS_DISABLED ? "merchant_operator_disable" : "merchant_operator_enable",
                "merchant_operator:" + operatorId,
                reason,
                normalizeIp(requestIp)
        );
        return toOperatorResponse(requireMerchantOperator(merchantId, operatorId));
    }

    private void changeStatus(AdminMerchantRow merchant, int expectedStatus, int status) {
        if (merchant.getStatus() == null || merchant.getStatus() != expectedStatus) {
            throw new IllegalArgumentException(status == STATUS_DISABLED
                    ? "商户当前状态不允许停用"
                    : "商户当前状态不允许恢复");
        }
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = currentScope(region);
        if (mapper.updateMerchantStatus(
                merchant.getId(),
                region,
                expectedStatus,
                status,
                scope.allCities(),
                scope.cityIds(),
                scope.shopIds()
        ) == 0) {
            throw new IllegalArgumentException("商户状态已变更，请刷新后重试");
        }
    }

    private AdminMerchantRow requireMerchant(Long merchantId) {
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = currentScope(region);
        AdminMerchantRow row = mapper.selectMerchantById(
                merchantId, region, scope.allCities(), scope.cityIds(), scope.shopIds());
        if (row == null) {
            throw new NotFoundException("商户不存在");
        }
        return row;
    }

    private AdminMerchantOperatorRow requireMerchantOperator(Long merchantId, Long operatorId) {
        String region = RegionContext.getRegion().name();
        AdminCityScope scope = currentScope(region);
        AdminMerchantOperatorRow row = mapper.selectMerchantOperatorById(
                merchantId,
                operatorId,
                region,
                scope.allCities(),
                scope.cityIds(),
                scope.shopIds()
        );
        if (row == null) {
            throw new NotFoundException("商户员工不存在");
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

    private AdminMerchantOperatorResponse toOperatorResponse(AdminMerchantOperatorRow row) {
        int status = row.getStatus() == null ? STATUS_DISABLED : row.getStatus();
        int shopScopeType = row.getShopScopeType() == null ? 2 : row.getShopScopeType();
        return new AdminMerchantOperatorResponse(
                row.getId(),
                row.getMerchantId(),
                safeText(row.getAccount()),
                safeText(row.getName()),
                safeText(row.getPhone()),
                safeText(row.getEmail()),
                shopScopeType,
                shopScopeType == 1 ? "全部门店" : "指定门店",
                mapper.selectMerchantOperatorShopIds(row.getId()),
                mapper.selectMerchantOperatorRoleNames(row.getId()),
                status,
                status == STATUS_ACTIVE ? "正常" : "已停用",
                status == STATUS_DISABLED ? latestOperatorDisableReason(row.getId()) : "",
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private AdminMerchantOperationLogResponse toOperationLogResponse(AdminMerchantOperationLogRow row) {
        return new AdminMerchantOperationLogResponse(
                row.getId(),
                row.getMerchantId(),
                row.getOperatorId(),
                safeText(row.getOperatorAccount()),
                safeText(row.getOperatorName()),
                safeText(row.getAction()),
                safeText(row.getTargetType()),
                row.getTargetId(),
                safeText(row.getDetail()),
                formatDateTime(row.getCreatedAt())
        );
    }

    private String latestDisableReason(Long merchantId) {
        String reason = adminAuditMapper.selectLatestAuditLogDetail("merchant_disable", "merchant:" + merchantId);
        return reason == null ? "" : reason;
    }

    private String latestOperatorDisableReason(Long operatorId) {
        String reason = adminAuditMapper.selectLatestAuditLogDetail(
                "merchant_operator_disable",
                "merchant_operator:" + operatorId
        );
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

    private AdminCityScope currentScope(String region) {
        AdminCityScope scope = currentAdmin().cityScopes().get(region);
        return scope == null ? new AdminCityScope(false, Set.of(), Set.of()) : scope;
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
