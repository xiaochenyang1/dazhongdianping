package com.tuowei.dazhongdianping.module.admin.management.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.management.mapper.AdminManagementMapper;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminImportBatchQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopListQuery;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopRow;
import com.tuowei.dazhongdianping.module.admin.management.model.ImportBatchRow;
import com.tuowei.dazhongdianping.module.admin.management.model.MerchantRow;
import com.tuowei.dazhongdianping.module.admin.management.model.request.AdminImportShopRecordRequest;
import com.tuowei.dazhongdianping.module.admin.management.model.request.AdminImportShopsRequest;
import com.tuowei.dazhongdianping.module.admin.management.model.request.AdminShopSaveRequest;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminImportBatchResponse;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminImportResultResponse;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminShopDetailResponse;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminShopSummaryResponse;
import com.tuowei.dazhongdianping.module.geodata.GeoReferenceLockService;
import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AdminManagementService {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final Path IMPORT_ERROR_DIR = Path.of("local-storage", "import-errors");

    private final AdminManagementMapper adminManagementMapper;
    private final GeoReferenceLockService geoReferenceLockService;
    private final ObjectMapper objectMapper;
    private final ApplicationEventPublisher applicationEventPublisher;

    public AdminManagementService(AdminManagementMapper adminManagementMapper,
                                  GeoReferenceLockService geoReferenceLockService,
                                  ObjectMapper objectMapper,
                                  ApplicationEventPublisher applicationEventPublisher) {
        this.adminManagementMapper = adminManagementMapper;
        this.geoReferenceLockService = geoReferenceLockService;
        this.objectMapper = objectMapper;
        this.applicationEventPublisher = applicationEventPublisher;
    }

    public PageResult<AdminShopSummaryResponse> listShops(AdminShopListQuery query) {
        query.normalize();
        query.setRegion(currentRegion().name());
        long total = adminManagementMapper.countAdminShops(query);
        List<AdminShopSummaryResponse> items = adminManagementMapper.selectAdminShops(query).stream()
                .map(this::toAdminShopSummaryResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    public AdminShopDetailResponse getShopDetail(Long shopId) {
        AdminShopRow row = adminManagementMapper.selectAdminShopDetail(shopId, currentRegion().name());
        if (row == null) {
            throw new NotFoundException("门店不存在");
        }
        return toAdminShopDetailResponse(row);
    }

    @Transactional
    public AdminShopDetailResponse createShop(AdminShopSaveRequest request) {
        Region region = requireWriteRegion(request.getRegion());
        AdminShopRow row = toAdminShopRow(region, request);
        validateShopReferences(row);
        adminManagementMapper.insertShop(row);
        publishSearchIndexChange(row.getId());
        return getShopDetail(row.getId());
    }

    @Transactional
    public AdminShopDetailResponse updateShop(Long shopId, AdminShopSaveRequest request) {
        AdminShopRow existing = requireShop(shopId);
        Region region = requireWriteRegion(request.getRegion());
        AdminShopRow row = toAdminShopRow(region, request);
        row.setId(existing.getId());
        validateShopReferences(row);
        int affected = adminManagementMapper.updateShop(row);
        if (affected == 0) {
            throw new NotFoundException("门店不存在");
        }
        publishSearchIndexChange(shopId);
        return getShopDetail(shopId);
    }

    @Transactional
    public void deleteShop(Long shopId) {
        requireShop(shopId);
        int affected = adminManagementMapper.softDeleteShop(shopId, currentRegion().name());
        if (affected == 0) {
            throw new NotFoundException("门店不存在");
        }
        publishSearchIndexChange(shopId);
    }

    @Transactional
    public AdminImportResultResponse importShops(AdminImportShopsRequest request) {
        Region region = requireWriteRegion(request.getRegion());
        AdminSession session = currentAdmin();
        geoReferenceLockService.lockInOrder(
                region.name(),
                request.getRecords().stream().map(AdminImportShopRecordRequest::getCategoryId).toList(),
                request.getRecords().stream().map(AdminImportShopRecordRequest::getCityId).toList(),
                request.getRecords().stream().map(AdminImportShopRecordRequest::getAreaId).toList());

        ImportBatchRow batchRow = new ImportBatchRow();
        batchRow.setAdminId(session.adminId());
        batchRow.setRegion(region.name());
        batchRow.setFileName(request.getFileName());
        batchRow.setTotal(request.getRecords().size());
        batchRow.setSuccess(0);
        batchRow.setFailed(0);
        batchRow.setStatus(0);
        batchRow.setErrorFile("");
        adminManagementMapper.insertImportBatch(batchRow);

        List<String> errors = new ArrayList<>();
        int success = 0;
        int failed = 0;

        for (int index = 0; index < request.getRecords().size(); index++) {
            AdminImportShopRecordRequest record = request.getRecords().get(index);
            try {
                AdminShopRow row = toAdminShopRow(region, record);
                validateImportRecord(record, row);
                adminManagementMapper.insertShop(row);
                publishSearchIndexChange(row.getId());
                success++;
            } catch (Exception exception) {
                failed++;
                errors.add("第 " + (index + 1) + " 条失败: " + exception.getMessage());
            }
        }

        batchRow.setSuccess(success);
        batchRow.setFailed(failed);
        batchRow.setStatus(success > 0 ? 1 : 2);
        batchRow.setErrorFile(failed > 0 ? writeImportErrorFile(batchRow, errors) : "");
        adminManagementMapper.updateImportBatch(batchRow);

        return new AdminImportResultResponse(
                batchRow.getId(),
                batchRow.getTotal(),
                success,
                failed,
                batchRow.getStatus(),
                importBatchStatusText(batchRow.getStatus()),
                batchRow.getErrorFile(),
                errors
        );
    }

    public PageResult<AdminImportBatchResponse> listImportBatches(AdminImportBatchQuery query) {
        query.normalize();
        query.setRegion(currentRegion().name());
        long total = adminManagementMapper.countImportBatches(query);
        List<AdminImportBatchResponse> items = adminManagementMapper.selectImportBatches(query).stream()
                .map(this::toAdminImportBatchResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    private String writeImportErrorFile(ImportBatchRow batchRow, List<String> errors) {
        try {
            Files.createDirectories(IMPORT_ERROR_DIR);
            Path errorFile = IMPORT_ERROR_DIR.resolve("import-batch-" + batchRow.getId() + "-errors.json");
            objectMapper.writerWithDefaultPrettyPrinter().writeValue(
                    errorFile.toFile(),
                    Map.of(
                            "batchId", batchRow.getId(),
                            "fileName", batchRow.getFileName(),
                            "region", batchRow.getRegion(),
                            "errors", errors
                    )
            );
            return errorFile.toString().replace("\\", "/");
        } catch (IOException exception) {
            throw new IllegalStateException("导入失败明细文件写入失败", exception);
        }
    }

    private void validateImportRecord(AdminImportShopRecordRequest record, AdminShopRow row) {
        validateShopReferences(row);
        row.setMerchantId(findOrCreateMerchant(record, row.getRegion()));
    }

    private Long findOrCreateMerchant(AdminImportShopRecordRequest record, String region) {
        MerchantRow merchant = adminManagementMapper.selectMerchantByAccount(record.getMerchantAccount().trim());
        if (merchant != null) {
            if (!region.equals(merchant.getRegion())) {
                throw new IllegalArgumentException("商户账号已存在但区域不一致");
            }
            return merchant.getId();
        }
        MerchantRow merchantRow = new MerchantRow();
        merchantRow.setAccount(record.getMerchantAccount().trim());
        merchantRow.setCompanyName(record.getCompanyName().trim());
        merchantRow.setContactName(record.getContactName().trim());
        merchantRow.setContactPhone(record.getContactPhone().trim());
        merchantRow.setRegion(region);
        merchantRow.setAuditStatus(1);
        merchantRow.setStatus(1);
        adminManagementMapper.insertMerchant(merchantRow);
        return merchantRow.getId();
    }

    private void validateShopReferences(AdminShopRow row) {
        geoReferenceLockService.requireActiveShopReferences(
                row.getRegion(), row.getCategoryId(), row.getCityId(), row.getAreaId());
        if (row.getMerchantId() != null && row.getMerchantId() > 0) {
            MerchantRow merchantRow = adminManagementMapper.selectMerchantById(row.getMerchantId());
            if (merchantRow == null) {
                throw new IllegalArgumentException("商户不存在");
            }
            if (!row.getRegion().equals(merchantRow.getRegion())) {
                throw new IllegalArgumentException("商户区域与门店区域不一致");
            }
        }
    }

    private AdminShopRow requireShop(Long shopId) {
        AdminShopRow row = adminManagementMapper.selectAdminShopDetail(shopId, currentRegion().name());
        if (row == null) {
            throw new NotFoundException("门店不存在");
        }
        return row;
    }

    private AdminShopRow toAdminShopRow(Region region, AdminShopSaveRequest request) {
        AdminShopRow row = new AdminShopRow();
        row.setMerchantId(request.getMerchantId() == null ? 0L : request.getMerchantId());
        row.setRegion(region.name());
        row.setCategoryId(request.getCategoryId());
        row.setCityId(request.getCityId());
        row.setAreaId(request.getAreaId());
        row.setName(request.getName().trim());
        row.setCoverUrl(request.getCoverUrl().trim());
        row.setPhone(request.getPhone().trim());
        row.setScore(request.getScore());
        row.setTasteScore(request.getTasteScore());
        row.setEnvScore(request.getEnvScore());
        row.setServiceScore(request.getServiceScore());
        row.setPricePerCapita(request.getPricePerCapita());
        row.setCurrency(normalizeCurrency(request.getCurrency(), row.getRegion()));
        row.setAddress(request.getAddress().trim());
        row.setLatitude(request.getLatitude());
        row.setLongitude(request.getLongitude());
        row.setBusinessHours(request.getBusinessHours().trim());
        row.setSummary(request.getSummary().trim());
        row.setHasDeal(Boolean.TRUE.equals(request.getHasDeal()));
        row.setOpenNow(Boolean.TRUE.equals(request.getOpenNow()));
        row.setStatus(request.getStatus() == null ? 1 : request.getStatus());
        row.setTags(joinTags(request.getTags()));
        return row;
    }

    private Region requireWriteRegion(String requestRegion) {
        if (!StringUtils.hasText(requestRegion)) {
            throw new IllegalArgumentException("region 不能为空");
        }
        Region currentRegion = currentRegion();
        Region bodyRegion;
        try {
            bodyRegion = Region.valueOf(requestRegion.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            throw new IllegalArgumentException("region 非法");
        }
        if (bodyRegion != currentRegion) {
            throw new IllegalArgumentException("region 必须与请求头 X-Region 一致");
        }
        return currentRegion;
    }

    private AdminShopRow toAdminShopRow(Region region, AdminImportShopRecordRequest request) {
        AdminShopRow row = new AdminShopRow();
        row.setMerchantId(0L);
        row.setRegion(region.name());
        row.setCategoryId(request.getCategoryId());
        row.setCityId(request.getCityId());
        row.setAreaId(request.getAreaId());
        row.setName(request.getShopName().trim());
        row.setCoverUrl(request.getCoverUrl().trim());
        row.setPhone(request.getPhone().trim());
        row.setScore(request.getScore());
        row.setTasteScore(request.getTasteScore());
        row.setEnvScore(request.getEnvScore());
        row.setServiceScore(request.getServiceScore());
        row.setPricePerCapita(request.getPricePerCapita());
        row.setCurrency(normalizeCurrency(request.getCurrency(), row.getRegion()));
        row.setAddress(request.getAddress().trim());
        row.setLatitude(request.getLatitude());
        row.setLongitude(request.getLongitude());
        row.setBusinessHours(request.getBusinessHours().trim());
        row.setSummary(request.getSummary().trim());
        row.setHasDeal(Boolean.TRUE.equals(request.getHasDeal()));
        row.setOpenNow(Boolean.TRUE.equals(request.getOpenNow()));
        row.setStatus(1);
        row.setTags(joinTags(request.getTags()));
        return row;
    }

    private AdminShopSummaryResponse toAdminShopSummaryResponse(AdminShopRow row) {
        return new AdminShopSummaryResponse(
                row.getId(),
                row.getMerchantId(),
                row.getMerchantName(),
                row.getName(),
                row.getRegion(),
                row.getCategoryName(),
                row.getCityName(),
                row.getAreaName(),
                row.getPricePerCapita(),
                row.getStatus(),
                shopStatusText(row.getStatus()),
                row.getOpenNow(),
                formatDateTime(row.getCreatedAt())
        );
    }

    private AdminShopDetailResponse toAdminShopDetailResponse(AdminShopRow row) {
        return new AdminShopDetailResponse(
                row.getId(),
                row.getMerchantId(),
                row.getMerchantName(),
                row.getRegion(),
                row.getCategoryId(),
                row.getCategoryName(),
                row.getCityId(),
                row.getCityName(),
                row.getAreaId(),
                row.getAreaName(),
                row.getName(),
                row.getCoverUrl(),
                row.getPhone(),
                row.getScore(),
                row.getTasteScore(),
                row.getEnvScore(),
                row.getServiceScore(),
                row.getPricePerCapita(),
                row.getCurrency(),
                row.getAddress(),
                row.getLatitude(),
                row.getLongitude(),
                row.getBusinessHours(),
                row.getSummary(),
                row.getHasDeal(),
                row.getOpenNow(),
                row.getStatus(),
                shopStatusText(row.getStatus()),
                splitTags(row.getTags()),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private AdminImportBatchResponse toAdminImportBatchResponse(ImportBatchRow row) {
        return new AdminImportBatchResponse(
                row.getId(),
                row.getFileName(),
                row.getRegion(),
                row.getTotal(),
                row.getSuccess(),
                row.getFailed(),
                row.getStatus(),
                importBatchStatusText(row.getStatus()),
                row.getErrorFile(),
                formatDateTime(row.getCreatedAt())
        );
    }

    private String normalizeCurrency(String currency, String region) {
        if (StringUtils.hasText(currency)) {
            return currency.trim().toUpperCase(Locale.ROOT);
        }
        return "EU".equals(region) ? "EUR" : "CNY";
    }

    private String joinTags(List<String> tags) {
        if (tags == null || tags.isEmpty()) {
            return "";
        }
        return tags.stream()
                .map(String::trim)
                .filter(StringUtils::hasText)
                .reduce((left, right) -> left + "," + right)
                .orElse("");
    }

    private List<String> splitTags(String tags) {
        if (!StringUtils.hasText(tags)) {
            return List.of();
        }
        return List.of(tags.split(",")).stream()
                .map(String::trim)
                .filter(StringUtils::hasText)
                .toList();
    }

    private String shopStatusText(Integer status) {
        return switch (status == null ? 1 : status) {
            case 0 -> "下线";
            case 2 -> "停业";
            default -> "营业";
        };
    }

    private String importBatchStatusText(Integer status) {
        return switch (status == null ? 0 : status) {
            case 1 -> "完成";
            case 2 -> "失败";
            default -> "处理中";
        };
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private Region currentRegion() {
        return RegionContext.getRegion();
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return session;
    }

    private void publishSearchIndexChange(Long shopId) {
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(shopId));
    }
}
