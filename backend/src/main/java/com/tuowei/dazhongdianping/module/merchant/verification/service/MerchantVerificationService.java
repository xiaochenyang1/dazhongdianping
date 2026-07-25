package com.tuowei.dazhongdianping.module.merchant.verification.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.merchant.mapper.MerchantWorkbenchMapper;
import com.tuowei.dazhongdianping.module.merchant.model.MerchantAccountRow;
import com.tuowei.dazhongdianping.module.merchant.verification.mapper.MerchantVerificationMapper;
import com.tuowei.dazhongdianping.module.merchant.verification.model.MerchantVerificationRow;
import com.tuowei.dazhongdianping.module.merchant.verification.model.request.MerchantVerificationApplyRequest;
import com.tuowei.dazhongdianping.module.merchant.verification.model.response.MerchantVerificationBadgeResponse;
import com.tuowei.dazhongdianping.module.merchant.verification.model.response.MerchantVerificationStatusResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class MerchantVerificationService {

    public static final int MERCHANT_VERIFICATION_AUDIT_BIZ_TYPE = 9;
    private static final int STATUS_NOT_APPLIED = 0;
    private static final int STATUS_PENDING = 1;
    private static final int STATUS_APPROVED = 2;
    private static final int STATUS_REJECTED = 3;
    private static final String BADGE_CODE = "verified_merchant";
    private static final String BADGE_LABEL = "认证商户";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final MerchantVerificationMapper verificationMapper;
    private final MerchantWorkbenchMapper merchantWorkbenchMapper;
    private final MerchantAuthorizationService authorizationService;
    private final AdminAuditMapper adminAuditMapper;
    private final ObjectMapper objectMapper;

    public MerchantVerificationService(MerchantVerificationMapper verificationMapper,
                                       MerchantWorkbenchMapper merchantWorkbenchMapper,
                                       MerchantAuthorizationService authorizationService,
                                       AdminAuditMapper adminAuditMapper,
                                       ObjectMapper objectMapper) {
        this.verificationMapper = verificationMapper;
        this.merchantWorkbenchMapper = merchantWorkbenchMapper;
        this.authorizationService = authorizationService;
        this.adminAuditMapper = adminAuditMapper;
        this.objectMapper = objectMapper;
    }

    public MerchantVerificationStatusResponse currentMerchantStatus() {
        MerchantSession session = currentMerchant();
        requireSettledMerchant(session);
        return toStatusResponse(verificationMapper.selectByMerchantId(session.merchantId()));
    }

    @Transactional
    public MerchantVerificationStatusResponse applyCurrentMerchant(MerchantVerificationApplyRequest request) {
        MerchantSession session = currentMerchant();
        authorizationService.requirePermission(session, "merchant:verify");
        MerchantAccountRow merchant = requireSettledMerchant(session);
        String region = currentRegion();
        if (!region.equals(merchant.getRegion())) {
            throw new UnauthorizedException("商户区域与当前请求区域不一致");
        }
        String reason = request.getReason().trim();
        String evidenceJson = writeEvidenceJson(request.getEvidenceUrls());
        MerchantVerificationRow existing = verificationMapper.selectByMerchantIdForUpdate(session.merchantId());
        if (existing != null && Objects.equals(existing.getStatus(), STATUS_PENDING)) {
            throw new IllegalArgumentException("当前已有待审核认证商户申请");
        }
        if (isApprovedAndEffective(existing)) {
            throw new IllegalArgumentException("当前已是认证商户，无需重复申请");
        }

        Long verificationId;
        if (existing == null) {
            MerchantVerificationRow row = new MerchantVerificationRow();
            row.setMerchantId(session.merchantId());
            row.setRegion(region);
            row.setReason(reason);
            row.setEvidenceUrls(evidenceJson);
            row.setStatus(STATUS_PENDING);
            row.setRejectReason("");
            row.setAuditBy(0L);
            row.setSubmittedBy(session.operatorId());
            row.setSubmittedAt(LocalDateTime.now());
            verificationMapper.insertVerification(row);
            verificationId = row.getId();
        } else {
            verificationMapper.resubmitVerification(
                    existing.getId(),
                    session.merchantId(),
                    region,
                    reason,
                    evidenceJson,
                    session.operatorId()
            );
            adminAuditMapper.invalidatePendingAuditTasksByBiz(
                    MERCHANT_VERIFICATION_AUDIT_BIZ_TYPE,
                    existing.getId(),
                    "任务失效：认证商户已重新提交"
            );
            verificationId = existing.getId();
        }

        createAuditTask(verificationId, region);
        return toStatusResponse(verificationMapper.selectByMerchantId(session.merchantId()));
    }

    public MerchantVerificationRow pendingVerificationForAudit(Long verificationId, String region) {
        return verificationMapper.selectPendingVerificationForAudit(verificationId, region);
    }

    public void approveVerification(MerchantVerificationRow verification, Long auditBy, String remark) {
        if (verificationMapper.approveVerification(verification.getId(), auditBy) == 0) {
            throw new IllegalArgumentException("认证商户状态已变化，请刷新后重试");
        }
    }

    public void rejectVerification(MerchantVerificationRow verification, Long auditBy, String reason) {
        if (verificationMapper.rejectVerification(verification.getId(), auditBy, reason) == 0) {
            throw new IllegalArgumentException("认证商户状态已变化，请刷新后重试");
        }
    }

    public MerchantVerificationBadgeResponse approvedBadge(Long merchantId, String region) {
        if (merchantId == null || merchantId <= 0) {
            return null;
        }
        MerchantVerificationRow row = verificationMapper.selectApprovedVerification(merchantId, region);
        return isApprovedAndEffective(row) ? badge() : null;
    }

    public Map<Long, MerchantVerificationBadgeResponse> approvedBadges(List<Long> merchantIds, String region) {
        List<Long> normalizedMerchantIds = merchantIds == null
                ? List.of()
                : merchantIds.stream()
                .filter(Objects::nonNull)
                .filter(merchantId -> merchantId > 0)
                .distinct()
                .toList();
        if (normalizedMerchantIds.isEmpty()) {
            return Map.of();
        }
        Map<Long, MerchantVerificationBadgeResponse> badges = new LinkedHashMap<>();
        for (MerchantVerificationRow row : verificationMapper.selectApprovedVerifications(normalizedMerchantIds, region)) {
            if (isApprovedAndEffective(row)) {
                badges.put(row.getMerchantId(), badge());
            }
        }
        return badges;
    }

    private MerchantAccountRow requireSettledMerchant(MerchantSession session) {
        MerchantAccountRow merchant = merchantWorkbenchMapper.selectMerchantAccount(session.merchantId(), session.account());
        if (merchant == null || merchant.getStatus() == null || merchant.getStatus() != 1) {
            throw new NotFoundException("商户不存在或已停用");
        }
        if (merchant.getAuditStatus() == null || merchant.getAuditStatus() != 1) {
            throw new IllegalArgumentException("商户资质尚未审核通过，不能申请认证商户");
        }
        return merchant;
    }

    private MerchantVerificationStatusResponse toStatusResponse(MerchantVerificationRow row) {
        if (row == null) {
            return new MerchantVerificationStatusResponse(
                    null,
                    STATUS_NOT_APPLIED,
                    statusText(STATUS_NOT_APPLIED),
                    "",
                    List.of(),
                    "",
                    null,
                    "",
                    "",
                    "",
                    ""
            );
        }
        return new MerchantVerificationStatusResponse(
                row.getId(),
                row.getStatus(),
                statusText(row.getStatus()),
                row.getReason() == null ? "" : row.getReason(),
                readEvidenceJson(row.getEvidenceUrls()),
                row.getRejectReason() == null ? "" : row.getRejectReason(),
                isApprovedAndEffective(row) ? badge() : null,
                formatDateTime(row.getSubmittedAt()),
                formatDateTime(row.getAuditedAt()),
                formatDateTime(row.getEffectiveStartAt()),
                formatDateTime(row.getEffectiveEndAt())
        );
    }

    private boolean isApprovedAndEffective(MerchantVerificationRow row) {
        if (row == null || !Objects.equals(row.getStatus(), STATUS_APPROVED)) {
            return false;
        }
        LocalDateTime now = LocalDateTime.now();
        if (row.getEffectiveStartAt() != null && row.getEffectiveStartAt().isAfter(now)) {
            return false;
        }
        return row.getEffectiveEndAt() == null || row.getEffectiveEndAt().isAfter(now);
    }

    private MerchantVerificationBadgeResponse badge() {
        return new MerchantVerificationBadgeResponse(BADGE_CODE, BADGE_LABEL);
    }

    private void createAuditTask(Long verificationId, String region) {
        AuditTaskRow row = new AuditTaskRow();
        row.setBizType(MERCHANT_VERIFICATION_AUDIT_BIZ_TYPE);
        row.setBizId(verificationId);
        row.setRegion(region);
        row.setMachineResult(0);
        row.setStatus(0);
        row.setAuditorId(0L);
        row.setRemark("");
        adminAuditMapper.insertAuditTask(row);
    }

    private String writeEvidenceJson(List<String> urls) {
        List<String> normalized = urls == null
                ? List.of()
                : urls.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(StringUtils::hasText)
                .distinct()
                .limit(5)
                .toList();
        try {
            return objectMapper.writeValueAsString(normalized);
        } catch (JsonProcessingException exception) {
            throw new IllegalArgumentException("认证材料链接不合法");
        }
    }

    private List<String> readEvidenceJson(String json) {
        if (!StringUtils.hasText(json)) {
            return List.of();
        }
        try {
            List<String> values = objectMapper.readValue(json, new TypeReference<>() {
            });
            return values == null ? List.of() : new ArrayList<>(values);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("认证材料数据损坏", exception);
        }
    }

    private String statusText(Integer status) {
        return switch (status == null ? STATUS_NOT_APPLIED : status) {
            case STATUS_PENDING -> "待审核";
            case STATUS_APPROVED -> "已通过";
            case STATUS_REJECTED -> "已驳回";
            default -> "未申请";
        };
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private String currentRegion() {
        Region region = RegionContext.getRegion();
        return region == null ? "CN" : region.name();
    }

    private MerchantSession currentMerchant() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }
}
