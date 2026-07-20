package com.tuowei.dazhongdianping.module.admin.merchant.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.merchant.model.request.AdminMerchantAuditRequest;
import com.tuowei.dazhongdianping.module.merchant.identity.mapper.MerchantIdentityMapper;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantApplicationRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AdminMerchantApplicationService {

    private final MerchantIdentityMapper merchantIdentityMapper;
    private final AdminAuditMapper adminAuditMapper;
    private final ObjectMapper objectMapper;

    public AdminMerchantApplicationService(
            MerchantIdentityMapper merchantIdentityMapper,
            AdminAuditMapper adminAuditMapper,
            ObjectMapper objectMapper
    ) {
        this.merchantIdentityMapper = merchantIdentityMapper;
        this.adminAuditMapper = adminAuditMapper;
        this.objectMapper = objectMapper;
    }

    public PageResult<Map<String, Object>> list(Integer status, Integer page, Integer pageSize) {
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        String region = RegionContext.getRegion().name();
        long total = merchantIdentityMapper.countApplications(region, status);
        List<Map<String, Object>> list = merchantIdentityMapper.selectApplications(
                region,
                status,
                normalizedPageSize,
                (normalizedPage - 1) * normalizedPageSize
        ).stream().map(this::applicationMap).toList();
        return new PageResult<>(
                list,
                total,
                normalizedPage,
                normalizedPageSize,
                (normalizedPage - 1) * normalizedPageSize + list.size() < total
        );
    }

    @Transactional
    public Map<String, Object> audit(
            Long merchantId,
            AdminMerchantAuditRequest request,
            String requestIp
    ) {
        AdminSession admin = admin();
        MerchantApplicationRow application = merchantIdentityMapper.selectAdminApplication(
                merchantId,
                RegionContext.getRegion().name()
        );
        if (application == null) {
            throw new NotFoundException("商户资质申请不存在");
        }
        String reason = StringUtils.hasText(request.reason()) ? request.reason().trim() : "";
        if (request.status() == 2 && reason.isEmpty()) {
            throw new IllegalArgumentException("驳回时必须填写原因");
        }
        if (merchantIdentityMapper.auditApplication(merchantId, request.status(), reason, admin.adminId()) == 0) {
            throw new IllegalArgumentException("商户资质申请已处理");
        }
        merchantIdentityMapper.updateMerchantAuditStatus(merchantId, request.status());
        adminAuditMapper.insertAuditLog(
                admin.adminId(),
                request.status() == 1 ? "merchant_application_pass" : "merchant_application_reject",
                "merchant:" + merchantId,
                reason,
                requestIp == null ? "" : requestIp
        );
        return applicationMap(merchantIdentityMapper.selectAdminApplication(
                merchantId,
                RegionContext.getRegion().name()
        ));
    }

    private Map<String, Object> applicationMap(MerchantApplicationRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("merchantId", row.getMerchantId());
        result.put("merchantAccount", row.getMerchantAccount());
        result.put("companyName", row.getCompanyName());
        result.put("region", row.getRegion());
        result.put("licenseUrl", row.getLicenseUrl());
        result.put("legalPerson", row.getLegalPerson());
        result.put("shopPhotoUrls", photoUrls(row.getShopPhotoUrls()));
        result.put("status", row.getStatus());
        result.put("statusText", switch (row.getStatus()) {
            case 1 -> "已通过";
            case 2 -> "已驳回";
            default -> "待审核";
        });
        result.put("rejectReason", row.getRejectReason());
        result.put("submittedAt", row.getSubmittedAt());
        result.put("auditedAt", row.getAuditedAt());
        return result;
    }

    private List<String> photoUrls(String json) {
        if (!StringUtils.hasText(json)) {
            return List.of();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<>() {
            });
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("商户资质照片数据损坏", exception);
        }
    }

    private AdminSession admin() {
        AdminSession admin = AdminSessionContext.get();
        if (admin == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return admin;
    }
}
