package com.tuowei.dazhongdianping.module.merchant.identity.service;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.identity.mapper.MerchantIdentityMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantRoleRow;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class MerchantAuthorizationService {

    private final MerchantIdentityMapper mapper;

    public MerchantAuthorizationService(MerchantIdentityMapper mapper) {
        this.mapper = mapper;
    }

    public List<String> permissions(MerchantSession session) {
        Set<String> permissions = new LinkedHashSet<>();
        for (MerchantRoleRow role : mapper.selectOperatorRoles(session.operatorId())) {
            Arrays.stream(role.getPermissions().split(","))
                    .map(String::trim)
                    .filter(value -> !value.isBlank())
                    .forEach(permissions::add);
        }
        return List.copyOf(permissions);
    }

    public void requirePermission(MerchantSession session, String permission) {
        if (!permissions(session).contains(permission)) {
            throw new UnauthorizedException("当前商户员工无此操作权限");
        }
    }

    public List<Long> scopedShopIds(MerchantSession session) {
        var operator = mapper.selectOperatorById(session.operatorId());
        if (operator == null || operator.getShopScopeType() == 1) {
            return null;
        }
        return mapper.selectOperatorShopIds(session.operatorId());
    }

    public void requireShop(MerchantSession session, String permission, Long shopId) {
        requirePermission(session, permission);
        if (mapper.countOwnedShops(session.merchantId(), List.of(shopId)) != 1) {
            throw new NotFoundException("门店不存在");
        }
        List<Long> scopedShopIds = scopedShopIds(session);
        if (scopedShopIds != null && !scopedShopIds.contains(shopId)) {
            throw new NotFoundException("门店不存在");
        }
    }
}
