package com.tuowei.dazhongdianping.module.merchant.identity.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.mapper.MerchantIdentityMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantOperatorRow;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantRoleRow;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantStaffCreateRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantStaffUpdateRequest;
import com.tuowei.dazhongdianping.common.api.PageResult;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantStaffService {

    private final MerchantIdentityMapper mapper;
    private final MerchantAuthorizationService authorizationService;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public MerchantStaffService(
            MerchantIdentityMapper mapper,
            MerchantAuthorizationService authorizationService
    ) {
        this.mapper = mapper;
        this.authorizationService = authorizationService;
    }

    @Transactional
    public Map<String, Object> create(MerchantStaffCreateRequest request) {
        MerchantSession owner = session();
        authorizationService.requirePermission(owner, "staff:manage");
        String account = request.account().trim().toLowerCase(Locale.ROOT);
        if (mapper.selectOperatorByAccount(account) != null) {
            throw new IllegalArgumentException("商户员工账号已存在");
        }
        if (request.shopScopeType() == null || (request.shopScopeType() != 1 && request.shopScopeType() != 2)) {
            throw new IllegalArgumentException("shopScopeType 仅支持 1 或 2");
        }
        List<Long> shopIds = request.shopIds() == null ? List.of() : request.shopIds().stream().distinct().toList();
        if (request.shopScopeType() == 2 && shopIds.isEmpty()) {
            throw new IllegalArgumentException("指定门店范围时 shopIds 不能为空");
        }
        if (!shopIds.isEmpty() && mapper.countOwnedShops(owner.merchantId(), shopIds) != shopIds.size()) {
            throw new IllegalArgumentException("门店范围包含无权管理的门店");
        }
        List<MerchantRoleRow> roles = mapper.selectRolesByIds(request.roleIds());
        if (roles.size() != request.roleIds().stream().distinct().count()
                || roles.stream().anyMatch(role -> "owner".equals(role.getCode()))) {
            throw new IllegalArgumentException("员工角色不合法");
        }

        MerchantOperatorRow operator = new MerchantOperatorRow();
        operator.setMerchantId(owner.merchantId());
        operator.setAccount(account);
        operator.setPasswordHash(passwordEncoder.encode(request.password()));
        operator.setName(request.name().trim());
        operator.setPhone(request.phone() == null ? "" : request.phone().trim());
        operator.setEmail(request.email() == null ? "" : request.email().trim());
        operator.setOperatorType(2);
        operator.setShopScopeType(request.shopScopeType());
        operator.setOperatorStatus(1);
        mapper.insertOperator(operator);
        request.roleIds().stream().distinct().forEach(roleId -> mapper.insertOperatorRole(operator.getId(), roleId));
        if (request.shopScopeType() == 2) {
            shopIds.forEach(shopId -> mapper.insertOperatorShop(operator.getId(), shopId));
        }
        mapper.insertOperationLog(owner.merchantId(), owner.operatorId(), "staff_create", operator.getId());
        return staffMap(mapper.selectOperatorById(operator.getId()));
    }

    @Transactional
    public Map<String, Object> changeStatus(Long staffId, Integer status) {
        MerchantSession owner = session();
        authorizationService.requirePermission(owner, "staff:manage");
        MerchantOperatorRow staff = mapper.selectMerchantOperator(staffId, owner.merchantId());
        if (staff == null || staff.getOperatorType() != 2) {
            throw new NotFoundException("商户员工不存在");
        }
        mapper.updateOperatorStatus(staffId, owner.merchantId(), status);
        mapper.insertOperationLog(owner.merchantId(), owner.operatorId(), "staff_status", staffId);
        return staffMap(mapper.selectOperatorById(staffId));
    }

    public PageResult<Map<String, Object>> list(Integer page, Integer pageSize) {
        MerchantSession owner = session();
        authorizationService.requirePermission(owner, "staff:manage");
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        long total = mapper.countMerchantStaff(owner.merchantId());
        List<Map<String, Object>> list = mapper.selectMerchantStaff(
                owner.merchantId(), normalizedPageSize, (normalizedPage - 1) * normalizedPageSize
        ).stream().map(this::staffMap).toList();
        return new PageResult<>(list, total, normalizedPage, normalizedPageSize,
                (normalizedPage - 1) * normalizedPageSize + list.size() < total);
    }

    @Transactional
    public Map<String, Object> update(Long staffId, MerchantStaffUpdateRequest request) {
        MerchantSession owner = session();
        authorizationService.requirePermission(owner, "staff:manage");
        MerchantOperatorRow staff = mapper.selectMerchantOperator(staffId, owner.merchantId());
        if (staff == null || staff.getOperatorType() != 2) {
            throw new NotFoundException("商户员工不存在");
        }
        validateScopeAndRoles(owner, request.shopScopeType(), request.shopIds(), request.roleIds());
        mapper.updateOperatorProfile(
                staffId,
                owner.merchantId(),
                request.name().trim(),
                request.phone() == null ? "" : request.phone().trim(),
                request.email() == null ? "" : request.email().trim(),
                request.shopScopeType()
        );
        mapper.deleteOperatorRoles(staffId);
        request.roleIds().stream().distinct().forEach(roleId -> mapper.insertOperatorRole(staffId, roleId));
        mapper.deleteOperatorShops(staffId);
        if (request.shopScopeType() == 2) {
            request.shopIds().stream().distinct().forEach(shopId -> mapper.insertOperatorShop(staffId, shopId));
        }
        mapper.insertOperationLog(owner.merchantId(), owner.operatorId(), "staff_update", staffId);
        return staffMap(mapper.selectOperatorById(staffId));
    }

    private void validateScopeAndRoles(
            MerchantSession owner,
            Integer shopScopeType,
            List<Long> requestedShopIds,
            List<Long> roleIds
    ) {
        if (shopScopeType == null || (shopScopeType != 1 && shopScopeType != 2)) {
            throw new IllegalArgumentException("shopScopeType 仅支持 1 或 2");
        }
        List<Long> shopIds = requestedShopIds == null ? List.of() : requestedShopIds.stream().distinct().toList();
        if (shopScopeType == 2 && shopIds.isEmpty()) {
            throw new IllegalArgumentException("指定门店范围时 shopIds 不能为空");
        }
        if (!shopIds.isEmpty() && mapper.countOwnedShops(owner.merchantId(), shopIds) != shopIds.size()) {
            throw new IllegalArgumentException("门店范围包含无权管理的门店");
        }
        List<MerchantRoleRow> roles = mapper.selectRolesByIds(roleIds);
        if (roles.size() != roleIds.stream().distinct().count()
                || roles.stream().anyMatch(role -> "owner".equals(role.getCode()))) {
            throw new IllegalArgumentException("员工角色不合法");
        }
    }

    private Map<String, Object> staffMap(MerchantOperatorRow operator) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", operator.getId());
        result.put("account", operator.getAccount());
        result.put("name", operator.getName());
        result.put("status", operator.getOperatorStatus());
        result.put("roles", mapper.selectOperatorRoles(operator.getId()).stream().map(role -> Map.of(
                "id", role.getId(), "code", role.getCode(), "name", role.getName()
        )).toList());
        result.put("shopScopeType", operator.getShopScopeType());
        result.put("shopIds", mapper.selectOperatorShopIds(operator.getId()));
        return result;
    }

    private MerchantSession session() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }
}
