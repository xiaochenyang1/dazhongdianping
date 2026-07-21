package com.tuowei.dazhongdianping.module.merchant.shop.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.geodata.GeoReferenceLockService;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.merchant.shop.mapper.MerchantShopChangeMapper;
import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangeDishRow;
import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangePhotoRow;
import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangeRow;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangeDishesRequest;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangePhotosRequest;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangeSaveRequest;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantShopChangeService {

    private static final int SHOP_CHANGE_BIZ_TYPE = 5;

    private final MerchantShopChangeMapper mapper;
    private final MerchantAuthorizationService authorizationService;
    private final AdminAuditMapper adminAuditMapper;
    private final GeoReferenceLockService geoReferenceLockService;

    public MerchantShopChangeService(MerchantShopChangeMapper mapper,
                                     MerchantAuthorizationService authorizationService,
                                     AdminAuditMapper adminAuditMapper,
                                     GeoReferenceLockService geoReferenceLockService) {
        this.mapper = mapper;
        this.authorizationService = authorizationService;
        this.adminAuditMapper = adminAuditMapper;
        this.geoReferenceLockService = geoReferenceLockService;
    }

    public PageResult<Map<String, Object>> list(Long shopId,
                                                 Integer status,
                                                 Integer changeType,
                                                 Integer page,
                                                 Integer pageSize) {
        MerchantSession session = merchant();
        authorizationService.requirePermission(session, "shop:edit");
        if (shopId != null) {
            authorizationService.requireShop(session, "shop:edit", shopId);
        }
        List<Long> shopIds = shopId == null ? authorizationService.scopedShopIds(session) : null;
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        long total = mapper.countChanges(session.merchantId(), region(), shopId, status, changeType, shopIds);
        List<Map<String, Object>> items = mapper.selectChanges(
                session.merchantId(), region(), shopId, status, changeType, shopIds,
                normalizedPageSize, (normalizedPage - 1) * normalizedPageSize
        ).stream().map(row -> changeMap(row, false)).toList();
        return new PageResult<>(items, total, normalizedPage, normalizedPageSize,
                (long) normalizedPage * normalizedPageSize < total);
    }

    public Map<String, Object> detail(Long changeId) {
        MerchantSession session = merchant();
        return changeMap(requireChange(changeId, session), true);
    }

    public ShopChangeRow pendingChangeForAudit(Long changeId, String auditRegion) {
        return mapper.selectPendingChangeForAudit(changeId, auditRegion);
    }

    public Long applyNewShop(ShopChangeRow change, Long auditBy) {
        if (change.getChangeType() == null || change.getChangeType() != 1) {
            throw new IllegalArgumentException("门店变更类型不是新建门店");
        }
        mapper.insertLiveShop(change);
        Long shopId = change.getTargetShopId();
        if (shopId == null || shopId <= 0) {
            throw new IllegalArgumentException("新门店主键生成失败");
        }
        mapper.insertLivePhotosFromChange(shopId, change.getId());
        mapper.insertLiveDishesFromChange(shopId, change.getId());
        if (mapper.approveChange(change.getId(), change.getRegion(), auditBy, shopId) != 1) {
            throw new IllegalArgumentException("门店草稿状态已变化，请刷新后重试");
        }
        mapper.insertOperationLog(change.getMerchantId(), change.getOperatorId(),
                "shop_change_pass", "shop", shopId, change.getName());
        return shopId;
    }

    public void validateExistingShopVersion(ShopChangeRow change) {
        if (change.getChangeType() == null || change.getChangeType() != 2) {
            throw new IllegalArgumentException("门店变更类型不是修改门店");
        }
        LocalDateTime currentUpdatedAt = mapper.selectLiveShopUpdatedAtForUpdate(
                change.getTargetShopId(), change.getMerchantId(), change.getRegion());
        if (currentUpdatedAt == null) {
            throw new NotFoundException("线上门店不存在");
        }
        if (change.getBaseUpdatedAt() == null || !currentUpdatedAt.equals(change.getBaseUpdatedAt())) {
            throw new IllegalArgumentException("线上门店已发生变化，请驳回后重新提交");
        }
    }

    public Long applyExistingShop(ShopChangeRow change, Long auditBy) {
        if (mapper.applyLiveShopFields(change) != 1) {
            throw new NotFoundException("线上门店不存在");
        }
        mapper.deleteLivePhotos(change.getTargetShopId());
        mapper.insertLivePhotosFromChange(change.getTargetShopId(), change.getId());
        mapper.deleteLiveDishes(change.getTargetShopId());
        mapper.insertLiveDishesFromChange(change.getTargetShopId(), change.getId());
        if (mapper.approveChange(change.getId(), change.getRegion(), auditBy, change.getTargetShopId()) != 1) {
            throw new IllegalArgumentException("门店草稿状态已变化，请刷新后重试");
        }
        mapper.insertOperationLog(change.getMerchantId(), change.getOperatorId(),
                "shop_change_pass", "shop", change.getTargetShopId(), change.getName());
        return change.getTargetShopId();
    }

    public void rejectChange(ShopChangeRow change, Long auditBy, String reason) {
        if (mapper.rejectChange(change.getId(), change.getRegion(), auditBy, reason) != 1) {
            throw new IllegalArgumentException("门店草稿状态已变化，请刷新后重试");
        }
        mapper.insertOperationLog(change.getMerchantId(), change.getOperatorId(),
                "shop_change_reject", "shop_change", change.getId(), reason);
    }

    @Transactional
    public Map<String, Object> createNewDraft() {
        MerchantSession session = merchant();
        authorizationService.requirePermission(session, "shop:edit");
        ShopChangeRow row = new ShopChangeRow();
        row.setMerchantId(session.merchantId());
        row.setOperatorId(session.operatorId());
        row.setRegion(region());
        row.setChangeType(1);
        row.setTargetShopId(0L);
        row.setCategoryId(0L);
        row.setCityId(0L);
        row.setAreaId(0L);
        row.setName("");
        row.setCoverUrl("");
        row.setPhone("");
        row.setPricePerCapita(BigDecimal.ZERO);
        row.setCurrency(expectedCurrency());
        row.setAddress("");
        row.setBusinessHours("");
        row.setSummary("");
        row.setOpenNow(true);
        row.setTags("");
        row.setStatus(0);
        mapper.insertChange(row);
        mapper.insertOperationLog(session.merchantId(), session.operatorId(),
                "shop_change_draft_create", "shop_change", row.getId(), "new_shop");
        return changeMap(requireChange(row.getId(), session), true);
    }

    @Transactional
    public Map<String, Object> createUpdateDraft(Long shopId) {
        MerchantSession session = merchant();
        authorizationService.requireShop(session, "shop:edit", shopId);
        ShopChangeRow existing = mapper.selectActiveChange(session.merchantId(), region(), shopId);
        if (existing != null) {
            return changeMap(existing, true);
        }
        ShopChangeRow row = mapper.selectLiveShopSnapshot(shopId, session.merchantId(), region());
        if (row == null) {
            throw new NotFoundException("门店不存在");
        }
        row.setOperatorId(session.operatorId());
        row.setStatus(0);
        mapper.insertChange(row);
        mapper.copyLivePhotos(row.getId(), shopId);
        mapper.copyLiveDishes(row.getId(), shopId);
        mapper.insertOperationLog(session.merchantId(), session.operatorId(),
                "shop_change_draft_create", "shop", shopId, row.getName());
        return changeMap(requireChange(row.getId(), session), true);
    }

    @Transactional
    public Map<String, Object> save(Long changeId, ShopChangeSaveRequest request) {
        MerchantSession session = merchant();
        ShopChangeRow row = editableChange(changeId, session);
        requireActiveReferences(request.categoryId(), request.cityId(), request.areaId());
        String currency = request.currency().trim().toUpperCase();
        if (!expectedCurrency().equals(currency)) {
            throw new IllegalArgumentException("门店币种与当前区域不匹配");
        }
        row.setOperatorId(session.operatorId());
        row.setCategoryId(request.categoryId());
        row.setCityId(request.cityId());
        row.setAreaId(request.areaId());
        row.setName(request.name().trim());
        row.setCoverUrl(request.coverUrl().trim());
        row.setPhone(trim(request.phone()));
        row.setPricePerCapita(request.pricePerCapita());
        row.setCurrency(currency);
        row.setAddress(request.address().trim());
        row.setLatitude(request.latitude());
        row.setLongitude(request.longitude());
        row.setBusinessHours(request.businessHours().trim());
        row.setSummary(request.summary().trim());
        row.setOpenNow(request.openNow());
        row.setTags(joinTags(request.tags()));
        if (mapper.updateChangeFields(row) != 1) {
            throw new IllegalArgumentException("门店草稿状态已变化，请刷新后重试");
        }
        return changeMap(requireChange(changeId, session), true);
    }

    @Transactional
    public Map<String, Object> savePhotos(Long changeId, ShopChangePhotosRequest request) {
        MerchantSession session = merchant();
        editableChange(changeId, session);
        mapper.deleteChangePhotos(changeId);
        mapper.insertChangePhotos(changeId, request.photos());
        return changeMap(requireChange(changeId, session), true);
    }

    @Transactional
    public Map<String, Object> saveDishes(Long changeId, ShopChangeDishesRequest request) {
        MerchantSession session = merchant();
        editableChange(changeId, session);
        mapper.deleteChangeDishes(changeId);
        if (!request.dishes().isEmpty()) {
            mapper.insertChangeDishes(changeId, request.dishes());
        }
        return changeMap(requireChange(changeId, session), true);
    }

    @Transactional
    public Map<String, Object> submit(Long changeId) {
        MerchantSession session = merchant();
        ShopChangeRow row = editableChange(changeId, session);
        List<ShopChangePhotoRow> photos = mapper.selectChangePhotos(changeId);
        validateComplete(row, photos);
        if (mapper.submitChange(changeId, session.merchantId(), region(), session.operatorId()) != 1) {
            throw new IllegalArgumentException("门店草稿状态已变化，请刷新后重试");
        }
        AuditTaskRow task = new AuditTaskRow();
        task.setBizType(SHOP_CHANGE_BIZ_TYPE);
        task.setBizId(changeId);
        task.setRegion(region());
        task.setMachineResult(0);
        task.setStatus(0);
        task.setAuditorId(0L);
        task.setRemark("");
        adminAuditMapper.insertAuditTask(task);
        mapper.insertOperationLog(session.merchantId(), session.operatorId(),
                "shop_change_submit", "shop_change", changeId, row.getName());
        return changeMap(requireChange(changeId, session), true);
    }

    private ShopChangeRow editableChange(Long changeId, MerchantSession session) {
        ShopChangeRow row = requireChange(changeId, session);
        if (row.getStatus() == 3) {
            mapper.resetRejectedChange(changeId, session.merchantId(), region(), session.operatorId());
            row = requireChange(changeId, session);
        }
        if (row.getStatus() != 0) {
            throw new IllegalArgumentException("门店草稿当前状态不允许编辑");
        }
        return row;
    }

    private ShopChangeRow requireChange(Long changeId, MerchantSession session) {
        authorizationService.requirePermission(session, "shop:edit");
        ShopChangeRow row = mapper.selectChange(changeId, session.merchantId(), region());
        if (row == null) {
            throw new NotFoundException("门店草稿不存在");
        }
        if (row.getTargetShopId() != null && row.getTargetShopId() > 0) {
            authorizationService.requireShop(session, "shop:edit", row.getTargetShopId());
        }
        return row;
    }

    public void requireActiveReferences(Long categoryId, Long cityId, Long areaId) {
        geoReferenceLockService.requireActiveShopReferences(region(), categoryId, cityId, areaId);
    }

    private void validateComplete(ShopChangeRow row, List<ShopChangePhotoRow> photos) {
        if (row.getCategoryId() == null || row.getCategoryId() <= 0
                || row.getCityId() == null || row.getCityId() <= 0
                || row.getAreaId() == null || row.getAreaId() <= 0
                || blank(row.getName()) || blank(row.getCoverUrl()) || blank(row.getAddress())
                || blank(row.getBusinessHours()) || blank(row.getSummary())) {
            throw new IllegalArgumentException("门店基础资料不完整");
        }
        if (photos.isEmpty()) {
            throw new IllegalArgumentException("门店至少需要一张图片");
        }
        boolean coverExists = photos.stream().anyMatch(photo -> photo.getPhotoType() == 1
                && row.getCoverUrl().equals(photo.getImageUrl()));
        if (!coverExists) {
            throw new IllegalArgumentException("门店封面必须存在于门店图相册中");
        }
    }

    private Map<String, Object> changeMap(ShopChangeRow row, boolean includeSnapshot) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("changeType", row.getChangeType());
        result.put("targetShopId", row.getTargetShopId());
        result.put("merchantId", row.getMerchantId());
        result.put("merchantName", row.getMerchantName());
        result.put("region", row.getRegion());
        result.put("categoryId", row.getCategoryId());
        result.put("cityId", row.getCityId());
        result.put("areaId", row.getAreaId());
        result.put("name", row.getName());
        result.put("coverUrl", row.getCoverUrl());
        result.put("phone", row.getPhone());
        result.put("pricePerCapita", row.getPricePerCapita());
        result.put("currency", row.getCurrency());
        result.put("address", row.getAddress());
        result.put("latitude", row.getLatitude());
        result.put("longitude", row.getLongitude());
        result.put("businessHours", row.getBusinessHours());
        result.put("summary", row.getSummary());
        result.put("openNow", row.getOpenNow());
        result.put("tags", splitTags(row.getTags()));
        result.put("status", row.getStatus());
        result.put("statusText", statusText(row.getStatus()));
        result.put("rejectReason", row.getRejectReason());
        result.put("submittedAt", row.getSubmittedAt());
        result.put("auditedAt", row.getAuditedAt());
        if (includeSnapshot) {
            result.put("photos", mapper.selectChangePhotos(row.getId()));
            result.put("dishes", mapper.selectChangeDishes(row.getId()));
        }
        return result;
    }

    private String statusText(Integer status) {
        return switch (status == null ? 0 : status) {
            case 1 -> "待审核";
            case 2 -> "已通过";
            case 3 -> "已驳回";
            case 4 -> "已失效";
            default -> "草稿";
        };
    }

    private String joinTags(List<String> tags) {
        if (tags == null) return "";
        return tags.stream().map(String::trim).filter(value -> !value.isBlank())
                .collect(Collectors.joining(","));
    }

    private List<String> splitTags(String tags) {
        if (blank(tags)) return List.of();
        return List.of(tags.split(",")).stream().map(String::trim)
                .filter(value -> !value.isBlank()).toList();
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private String expectedCurrency() {
        return "EU".equals(region()) ? "EUR" : "CNY";
    }

    private MerchantSession merchant() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) throw new UnauthorizedException("商户登录状态不存在");
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
