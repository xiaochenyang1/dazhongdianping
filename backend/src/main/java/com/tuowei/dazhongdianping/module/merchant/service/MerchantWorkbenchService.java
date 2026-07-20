package com.tuowei.dazhongdianping.module.merchant.service;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.browse.model.ShopListQuery;
import com.tuowei.dazhongdianping.module.browse.model.ShopListRow;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.mapper.MerchantWorkbenchMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.mapper.MerchantIdentityMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.merchant.model.MerchantAccountRow;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantAccountResponse;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantOperatorResponse;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantProfileResponse;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantRoleListResponse;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantRoleResponse;
import java.util.Arrays;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class MerchantWorkbenchService {

    private final MerchantWorkbenchMapper merchantWorkbenchMapper;
    private final MerchantIdentityMapper merchantIdentityMapper;
    private final MerchantAuthorizationService authorizationService;

    public MerchantWorkbenchService(MerchantWorkbenchMapper merchantWorkbenchMapper,
                                    MerchantIdentityMapper merchantIdentityMapper,
                                    MerchantAuthorizationService authorizationService) {
        this.merchantWorkbenchMapper = merchantWorkbenchMapper;
        this.merchantIdentityMapper = merchantIdentityMapper;
        this.authorizationService = authorizationService;
    }

    public MerchantAccountResponse getAccountSummary(MerchantSession session, Region region) {
        MerchantAccountRow row = requireMerchantScope(session, region);
        MerchantProfileResponse merchant = new MerchantProfileResponse(row.getId(), row.getCompanyName(), row.getRegion());
        var operatorRow = merchantIdentityMapper.selectOperatorById(session.operatorId());
        MerchantOperatorResponse operator = new MerchantOperatorResponse(
                session.operatorId(), session.operatorType() == 1 ? "owner" : "staff", operatorRow.getName());
        return new MerchantAccountResponse(merchant, operator, authorizationService.permissions(session));
    }

    public MerchantRoleListResponse listRoles(MerchantSession session, Region region) {
        requireMerchantScope(session, region);
        return new MerchantRoleListResponse(merchantIdentityMapper.selectAllRoles().stream()
                .map(role -> new MerchantRoleResponse(role.getId(), role.getCode(), role.getName(), splitTags(role.getPermissions())))
                .toList());
    }

    public PageResult<ShopListItemResponse> listShops(MerchantSession session, Region region, ShopListQuery query) {
        requireMerchantScope(session, region);
        query.normalize();
        List<Long> shopIds = authorizationService.scopedShopIds(session);
        if (shopIds != null && shopIds.isEmpty()) {
            return new PageResult<>(List.of(), 0, query.getPage(), query.getPageSize(), false);
        }
        long total = merchantWorkbenchMapper.countMerchantShops(session.merchantId(), region.name(), shopIds, query);
        List<ShopListItemResponse> items = merchantWorkbenchMapper.selectMerchantShops(
                        session.merchantId(),
                        region.name(),
                        shopIds,
                        query
                ).stream()
                .map(this::toShopListItemResponse)
                .toList();
        return new PageResult<>(
                items,
                total,
                query.getPage(),
                query.getPageSize(),
                query.getOffset() + items.size() < total
        );
    }

    private MerchantAccountRow requireMerchantScope(MerchantSession session, Region region) {
        MerchantAccountRow row = merchantWorkbenchMapper.selectMerchantAccount(session.merchantId(), session.account());
        if (row == null) {
            throw new UnauthorizedException("商户账号状态不可用");
        }
        if (row.getStatus() != 1) {
            throw new UnauthorizedException("商户账号状态不可用");
        }
        if (row.getAuditStatus() != 1) {
            throw new UnauthorizedException("商户资质尚未审核通过");
        }
        if (!region.name().equals(row.getRegion())) {
            throw new UnauthorizedException("当前区域无权访问该商户工作台");
        }
        return row;
    }

    private ShopListItemResponse toShopListItemResponse(ShopListRow row) {
        return new ShopListItemResponse(
                row.getId(),
                row.getName(),
                row.getCoverUrl(),
                row.getScore(),
                row.getPricePerCapita(),
                row.getAddress(),
                row.getAreaName(),
                row.getCityName(),
                row.getHasDeal(),
                row.getOpenNow(),
                splitTags(row.getTags())
        );
    }

    private List<String> splitTags(String tags) {
        if (tags == null || tags.isBlank()) {
            return List.of();
        }
        return Arrays.stream(tags.split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .toList();
    }
}
