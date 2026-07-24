package com.tuowei.dazhongdianping.module.auth.appeal.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.auth.appeal.mapper.UserBanAppealMapper;
import com.tuowei.dazhongdianping.module.auth.appeal.model.UserBanAppealRow;
import com.tuowei.dazhongdianping.module.auth.appeal.model.request.UserBanAppealQueryRequest;
import com.tuowei.dazhongdianping.module.auth.appeal.model.request.UserBanAppealSubmitRequest;
import com.tuowei.dazhongdianping.module.auth.appeal.model.response.UserBanAppealResponse;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.auth.model.VerificationCodeRow;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class UserBanAppealService {

    public static final int USER_APPEAL_AUDIT_BIZ_TYPE = 8;
    public static final int STATUS_PENDING = 0;
    public static final int STATUS_APPROVED = 1;
    public static final int STATUS_REJECTED = 2;

    private static final String NOTIFICATION_TYPE = "account.ban_appeal";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final UserBanAppealMapper appealMapper;
    private final AuthCommandMapper authCommandMapper;
    private final AdminAuditMapper adminAuditMapper;
    private final NotificationService notificationService;

    public UserBanAppealService(UserBanAppealMapper appealMapper,
                                AuthCommandMapper authCommandMapper,
                                AdminAuditMapper adminAuditMapper,
                                NotificationService notificationService) {
        this.appealMapper = appealMapper;
        this.authCommandMapper = authCommandMapper;
        this.adminAuditMapper = adminAuditMapper;
        this.notificationService = notificationService;
    }

    @Transactional
    public UserBanAppealResponse submitAppeal(UserBanAppealSubmitRequest request) {
        int targetType = normalizeTargetType(request.getType());
        String account = normalizeAccount(request.getAccount(), targetType);
        String reason = request.getReason().trim();
        requireVerificationCode(targetType, account, request.getCode());

        AppUserRow userRow = targetType == 1
                ? authCommandMapper.selectUserByEmail(account)
                : authCommandMapper.selectUserByPhone(account);
        if (userRow == null) {
            throw new IllegalArgumentException("账号不存在");
        }
        if (userRow.getStatus() != null && userRow.getStatus() == 1) {
            throw new IllegalArgumentException("账号未被封禁，无需申诉");
        }
        if (appealMapper.selectPendingAppealByUserIdForUpdate(userRow.getId()) != null) {
            throw new IllegalArgumentException("已有申诉正在处理中，请耐心等待审核结果");
        }

        UserBanAppealRow row = new UserBanAppealRow();
        row.setUserId(userRow.getId());
        row.setRegion(normalizeRegion(userRow.getPreferredRegion()));
        row.setAccount(account);
        row.setReason(reason);
        row.setStatus(STATUS_PENDING);
        row.setRejectReason("");
        row.setAuditBy(0L);
        appealMapper.insertAppeal(row);

        createAuditTask(row.getId(), row.getRegion());
        return toResponse(appealMapper.selectAppealById(row.getId()));
    }

    @Transactional
    public UserBanAppealResponse queryLatestAppeal(UserBanAppealQueryRequest request) {
        int targetType = normalizeTargetType(request.getType());
        String account = normalizeAccount(request.getAccount(), targetType);
        requireVerificationCode(targetType, account, request.getCode());

        AppUserRow userRow = targetType == 1
                ? authCommandMapper.selectUserByEmail(account)
                : authCommandMapper.selectUserByPhone(account);
        if (userRow == null) {
            throw new IllegalArgumentException("账号不存在");
        }
        UserBanAppealRow row = appealMapper.selectLatestAppealByUserId(userRow.getId());
        if (row == null) {
            throw new NotFoundException("该账号暂无申诉记录");
        }
        return toResponse(row);
    }

    public UserBanAppealRow pendingAppealForAudit(Long appealId, String region) {
        return appealMapper.selectPendingAppealForAudit(appealId, region);
    }

    public void approveAppeal(UserBanAppealRow appeal, Long auditBy) {
        if (appealMapper.resolveAppeal(appeal.getId(), STATUS_APPROVED, auditBy, "") == 0) {
            throw new IllegalArgumentException("申诉状态已变化，请刷新后重试");
        }
        notificationService.create(
                appeal.getUserId(),
                appeal.getRegion(),
                NOTIFICATION_TYPE,
                "封禁申诉已通过",
                "你的封禁申诉已通过，账号已解封，现在可以正常登录使用了。",
                ""
        );
    }

    public void rejectAppeal(UserBanAppealRow appeal, Long auditBy, String reason) {
        if (appealMapper.resolveAppeal(appeal.getId(), STATUS_REJECTED, auditBy, reason) == 0) {
            throw new IllegalArgumentException("申诉状态已变化，请刷新后重试");
        }
        notificationService.create(
                appeal.getUserId(),
                appeal.getRegion(),
                NOTIFICATION_TYPE,
                "封禁申诉已驳回",
                "你的封禁申诉未通过：" + reason,
                ""
        );
    }

    public void resolvePendingAppealsOnManualUnban(Long userId, Long auditBy) {
        for (UserBanAppealRow appeal : appealMapper.selectPendingAppealsByUserId(userId)) {
            appealMapper.resolveAppeal(appeal.getId(), STATUS_APPROVED, auditBy, "");
            adminAuditMapper.invalidatePendingAuditTasksByBiz(
                    USER_APPEAL_AUDIT_BIZ_TYPE,
                    appeal.getId(),
                    "任务失效：管理员已直接解封"
            );
            notificationService.create(
                    appeal.getUserId(),
                    appeal.getRegion(),
                    NOTIFICATION_TYPE,
                    "账号已解封",
                    "管理员已解除你的账号封禁，关联的申诉已自动通过，现在可以正常登录使用了。",
                    ""
            );
        }
    }

    public long countPendingAppeals(Long userId) {
        return appealMapper.countPendingAppealsByUserId(userId);
    }

    public UserBanAppealRow latestAppeal(Long userId) {
        return appealMapper.selectLatestAppealByUserId(userId);
    }

    public String latestBanReason(Long userId) {
        String detail = adminAuditMapper.selectLatestAuditLogDetail("user_ban", "app_user:" + userId);
        return detail == null ? "" : detail;
    }

    public String statusTextOf(Integer status) {
        return statusText(status);
    }

    private void createAuditTask(Long appealId, String region) {
        AuditTaskRow row = new AuditTaskRow();
        row.setBizType(USER_APPEAL_AUDIT_BIZ_TYPE);
        row.setBizId(appealId);
        row.setRegion(region);
        row.setMachineResult(0);
        row.setStatus(0);
        row.setAuditorId(0L);
        row.setRemark("");
        adminAuditMapper.insertAuditTask(row);
    }

    private void requireVerificationCode(int targetType, String target, String code) {
        VerificationCodeRow row = authCommandMapper.selectLatestVerificationCode("appeal", targetType, target);
        String codeHash = sha256Hex(code.trim());
        if (row == null
                || row.getStatus() == null
                || row.getStatus() != 0
                || !codeHash.equals(row.getCodeHash())
                || row.getExpireAt() == null
                || !row.getExpireAt().isAfter(LocalDateTime.now())) {
            throw new IllegalArgumentException("验证码无效或已过期");
        }
        if (authCommandMapper.markVerificationCodeUsed(row.getId()) != 1) {
            throw new IllegalArgumentException("验证码无效或已过期");
        }
    }

    private int normalizeTargetType(String type) {
        String value = type == null ? "" : type.trim().toLowerCase(Locale.ROOT);
        return switch (value) {
            case "email" -> 1;
            case "phone" -> 2;
            default -> throw new IllegalArgumentException("type 不支持");
        };
    }

    private String normalizeAccount(String account, int targetType) {
        String value = account == null ? "" : account.trim();
        if (!StringUtils.hasText(value)) {
            throw new IllegalArgumentException("account 不能为空");
        }
        if (targetType == 1 && !value.contains("@")) {
            throw new IllegalArgumentException("邮箱格式不合法");
        }
        if (targetType == 2 && value.length() < 6) {
            throw new IllegalArgumentException("手机号格式不合法");
        }
        return value;
    }

    private String normalizeRegion(String preferredRegion) {
        if (!StringUtils.hasText(preferredRegion)) {
            return Region.CN.name();
        }
        return Region.fromHeader(preferredRegion).name();
    }

    private UserBanAppealResponse toResponse(UserBanAppealRow row) {
        return new UserBanAppealResponse(
                row.getId(),
                row.getStatus(),
                statusText(row.getStatus()),
                row.getReason() == null ? "" : row.getReason(),
                row.getRejectReason() == null ? "" : row.getRejectReason(),
                latestBanReason(row.getUserId()),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getAuditedAt())
        );
    }

    private String statusText(Integer status) {
        return switch (status == null ? STATUS_PENDING : status) {
            case STATUS_APPROVED -> "已通过";
            case STATUS_REJECTED -> "已驳回";
            default -> "待审核";
        };
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(messageDigest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 不可用", exception);
        }
    }
}
