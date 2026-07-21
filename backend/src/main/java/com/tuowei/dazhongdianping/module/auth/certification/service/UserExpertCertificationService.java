package com.tuowei.dazhongdianping.module.auth.certification.service;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.auth.certification.mapper.UserExpertCertificationMapper;
import com.tuowei.dazhongdianping.module.auth.certification.model.UserExpertCertificationRow;
import com.tuowei.dazhongdianping.module.auth.model.request.UserExpertCertificationApplyRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.UserExpertCertificationBadgeResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.UserExpertCertificationStatusResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserExpertCertificationService {

    private static final int EXPERT_CERTIFICATION_AUDIT_BIZ_TYPE = 7;
    private static final int STATUS_NOT_APPLIED = 0;
    private static final int STATUS_PENDING = 1;
    private static final int STATUS_APPROVED = 2;
    private static final int STATUS_REJECTED = 3;
    private static final String BADGE_CODE = "local_expert";
    private static final String BADGE_LABEL = "本地达人";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final UserExpertCertificationMapper certificationMapper;
    private final AdminAuditMapper adminAuditMapper;

    public UserExpertCertificationService(UserExpertCertificationMapper certificationMapper,
                                          AdminAuditMapper adminAuditMapper) {
        this.certificationMapper = certificationMapper;
        this.adminAuditMapper = adminAuditMapper;
    }

    public UserExpertCertificationStatusResponse currentUserStatus() {
        UserSession session = currentUser();
        return toStatusResponse(certificationMapper.selectByUserAndRegion(session.userId(), currentRegion()));
    }

    public UserExpertCertificationStatusResponse currentUserStatus(Long userId, String region) {
        return toStatusResponse(certificationMapper.selectByUserAndRegion(userId, region));
    }

    @Transactional
    public UserExpertCertificationStatusResponse applyCurrentUser(UserExpertCertificationApplyRequest request) {
        UserSession session = currentUser();
        String region = currentRegion();
        String reason = request.getReason().trim();
        UserExpertCertificationRow existing = certificationMapper.selectByUserAndRegionForUpdate(session.userId(), region);
        if (existing != null && Objects.equals(existing.getStatus(), STATUS_PENDING)) {
            throw new IllegalArgumentException("当前已有待审核达人认证申请");
        }
        if (isApprovedAndEffective(existing)) {
            throw new IllegalArgumentException("当前已是认证达人，无需重复申请");
        }

        Long certificationId;
        if (existing == null) {
            UserExpertCertificationRow row = new UserExpertCertificationRow();
            row.setUserId(session.userId());
            row.setRegion(region);
            row.setReason(reason);
            row.setStatus(STATUS_PENDING);
            row.setRejectReason("");
            row.setAuditBy(0L);
            row.setSubmittedAt(LocalDateTime.now());
            certificationMapper.insertCertification(row);
            certificationId = row.getId();
        } else {
            certificationMapper.resubmitCertification(existing.getId(), session.userId(), region, reason);
            adminAuditMapper.invalidatePendingAuditTasksByBiz(
                    EXPERT_CERTIFICATION_AUDIT_BIZ_TYPE,
                    existing.getId(),
                    "任务失效：达人认证已重新提交"
            );
            certificationId = existing.getId();
        }

        createAuditTask(certificationId, region);
        return toStatusResponse(certificationMapper.selectByUserAndRegion(session.userId(), region));
    }

    public UserExpertCertificationRow pendingCertificationForAudit(Long certificationId, String region) {
        return certificationMapper.selectPendingCertificationForAudit(certificationId, region);
    }

    public void approveCertification(UserExpertCertificationRow certification, Long auditBy, String remark) {
        if (certificationMapper.approveCertification(certification.getId(), auditBy) == 0) {
            throw new IllegalArgumentException("达人认证状态已变化，请刷新后重试");
        }
    }

    public void rejectCertification(UserExpertCertificationRow certification, Long auditBy, String reason) {
        if (certificationMapper.rejectCertification(certification.getId(), auditBy, reason) == 0) {
            throw new IllegalArgumentException("达人认证状态已变化，请刷新后重试");
        }
    }

    public UserExpertCertificationBadgeResponse approvedBadge(Long userId, String region) {
        if (userId == null || userId <= 0) {
            return null;
        }
        UserExpertCertificationRow row = certificationMapper.selectApprovedCertification(userId, region);
        return isApprovedAndEffective(row) ? badge() : null;
    }

    public Map<Long, UserExpertCertificationBadgeResponse> approvedBadges(List<Long> userIds, String region) {
        List<Long> normalizedUserIds = userIds == null
                ? List.of()
                : userIds.stream()
                .filter(Objects::nonNull)
                .filter(userId -> userId > 0)
                .distinct()
                .toList();
        if (normalizedUserIds.isEmpty()) {
            return Map.of();
        }
        Map<Long, UserExpertCertificationBadgeResponse> badges = new LinkedHashMap<>();
        for (UserExpertCertificationRow row : certificationMapper.selectApprovedCertifications(normalizedUserIds, region)) {
            if (isApprovedAndEffective(row)) {
                badges.put(row.getUserId(), badge());
            }
        }
        return badges;
    }

    private UserExpertCertificationStatusResponse toStatusResponse(UserExpertCertificationRow row) {
        if (row == null) {
            return new UserExpertCertificationStatusResponse(
                    null,
                    STATUS_NOT_APPLIED,
                    statusText(STATUS_NOT_APPLIED),
                    "",
                    "",
                    null,
                    "",
                    "",
                    "",
                    ""
            );
        }
        return new UserExpertCertificationStatusResponse(
                row.getId(),
                row.getStatus(),
                statusText(row.getStatus()),
                row.getReason() == null ? "" : row.getReason(),
                row.getRejectReason() == null ? "" : row.getRejectReason(),
                isApprovedAndEffective(row) ? badge() : null,
                formatDateTime(row.getSubmittedAt()),
                formatDateTime(row.getAuditedAt()),
                formatDateTime(row.getEffectiveStartAt()),
                formatDateTime(row.getEffectiveEndAt())
        );
    }

    private boolean isApprovedAndEffective(UserExpertCertificationRow row) {
        if (row == null || !Objects.equals(row.getStatus(), STATUS_APPROVED)) {
            return false;
        }
        LocalDateTime now = LocalDateTime.now();
        if (row.getEffectiveStartAt() != null && row.getEffectiveStartAt().isAfter(now)) {
            return false;
        }
        return row.getEffectiveEndAt() == null || row.getEffectiveEndAt().isAfter(now);
    }

    private UserExpertCertificationBadgeResponse badge() {
        return new UserExpertCertificationBadgeResponse(BADGE_CODE, BADGE_LABEL);
    }

    private void createAuditTask(Long certificationId, String region) {
        AuditTaskRow row = new AuditTaskRow();
        row.setBizType(EXPERT_CERTIFICATION_AUDIT_BIZ_TYPE);
        row.setBizId(certificationId);
        row.setRegion(region);
        row.setMachineResult(0);
        row.setStatus(0);
        row.setAuditorId(0L);
        row.setRemark("");
        adminAuditMapper.insertAuditTask(row);
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
        return RegionContext.getRegion().name();
    }

    private UserSession currentUser() {
        UserSession session = UserSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return session;
    }
}
