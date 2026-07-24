package com.tuowei.dazhongdianping.module.admin.user.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.user.mapper.AdminAppUserMapper;
import com.tuowei.dazhongdianping.module.admin.user.model.AdminAppUserQuery;
import com.tuowei.dazhongdianping.module.admin.user.model.AdminAppUserRow;
import com.tuowei.dazhongdianping.module.admin.user.model.request.AdminAppUserStatusRequest;
import com.tuowei.dazhongdianping.module.admin.user.model.response.AdminAppUserDetailResponse;
import com.tuowei.dazhongdianping.module.admin.user.model.response.AdminAppUserResponse;
import com.tuowei.dazhongdianping.module.auth.appeal.service.UserBanAppealService;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class AdminAppUserService {

    public static final int STATUS_NORMAL = 1;
    public static final int STATUS_BANNED = 2;
    public static final int STATUS_DELETED = 3;

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminAppUserMapper mapper;
    private final AuthCommandMapper authCommandMapper;
    private final AdminAuditMapper adminAuditMapper;
    private final UserBanAppealService userBanAppealService;

    public AdminAppUserService(AdminAppUserMapper mapper,
                               AuthCommandMapper authCommandMapper,
                               AdminAuditMapper adminAuditMapper,
                               UserBanAppealService userBanAppealService) {
        this.mapper = mapper;
        this.authCommandMapper = authCommandMapper;
        this.adminAuditMapper = adminAuditMapper;
        this.userBanAppealService = userBanAppealService;
    }

    public PageResult<AdminAppUserResponse> listUsers(AdminAppUserQuery query) {
        query.normalize();
        long total = mapper.countUsers(query);
        List<AdminAppUserResponse> list = mapper.selectUsers(query).stream()
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

    public AdminAppUserDetailResponse getUserDetail(Long userId) {
        AdminAppUserRow row = requireUser(userId);
        int status = effectiveStatus(row);
        var latestAppeal = userBanAppealService.latestAppeal(userId);
        return new AdminAppUserDetailResponse(
                row.getId(),
                safeText(row.getNickname()),
                safeText(row.getAvatar()),
                safeText(row.getEmail()),
                safeText(row.getPhone()),
                row.getGender(),
                safeText(row.getSignature()),
                safeText(row.getPreferredRegion()),
                row.getGrowthValue(),
                row.getLevel(),
                row.getPoints(),
                status,
                statusText(status),
                formatDateTime(row.getLastLoginAt()),
                formatDateTime(row.getCreatedAt()),
                mapper.countReviewsByUserId(userId),
                mapper.countPostsByUserId(userId),
                mapper.countOrdersByUserId(userId),
                mapper.countReservationsByUserId(userId),
                mapper.countFavoritesByUserId(userId),
                mapper.countActiveSessionsByUserId(userId),
                status == STATUS_BANNED ? userBanAppealService.latestBanReason(userId) : "",
                userBanAppealService.countPendingAppeals(userId),
                latestAppeal == null ? "" : userBanAppealService.statusTextOf(latestAppeal.getStatus())
        );
    }

    @Transactional
    public AdminAppUserResponse updateUserStatus(Long userId, AdminAppUserStatusRequest request, String requestIp) {
        String action = normalizeAction(request.getAction());
        String reason = StringUtils.hasText(request.getReason()) ? request.getReason().trim() : "";
        AdminAppUserRow row = requireUser(userId);
        if (Boolean.TRUE.equals(row.getIsDeleted())) {
            throw new IllegalArgumentException("用户已注销，不能变更状态");
        }

        if ("ban".equals(action)) {
            if (!StringUtils.hasText(reason)) {
                throw new IllegalArgumentException("封禁必须填写原因");
            }
            if (row.getStatus() == null || row.getStatus() != STATUS_NORMAL) {
                throw new IllegalArgumentException("用户当前状态不允许封禁");
            }
            if (mapper.updateUserStatus(userId, STATUS_NORMAL, STATUS_BANNED) == 0) {
                throw new IllegalArgumentException("用户状态已变更，请刷新后重试");
            }
            authCommandMapper.revokeUserSessionsByUserId(userId);
            adminAuditMapper.insertAuditLog(
                    currentAdmin().adminId(),
                    "user_ban",
                    "app_user:" + userId,
                    reason,
                    normalizeIp(requestIp)
            );
        } else {
            if (row.getStatus() == null || row.getStatus() != STATUS_BANNED) {
                throw new IllegalArgumentException("用户当前状态不允许解封");
            }
            if (mapper.updateUserStatus(userId, STATUS_BANNED, STATUS_NORMAL) == 0) {
                throw new IllegalArgumentException("用户状态已变更，请刷新后重试");
            }
            userBanAppealService.resolvePendingAppealsOnManualUnban(userId, currentAdmin().adminId());
            adminAuditMapper.insertAuditLog(
                    currentAdmin().adminId(),
                    "user_unban",
                    "app_user:" + userId,
                    reason,
                    normalizeIp(requestIp)
            );
        }
        return toResponse(mapper.selectUserById(userId));
    }

    private AdminAppUserRow requireUser(Long userId) {
        AdminAppUserRow row = mapper.selectUserById(userId);
        if (row == null) {
            throw new NotFoundException("用户不存在");
        }
        return row;
    }

    private String normalizeAction(String action) {
        String value = action == null ? "" : action.trim().toLowerCase(Locale.ROOT);
        return switch (value) {
            case "ban", "unban" -> value;
            default -> throw new IllegalArgumentException("action 只支持 ban 或 unban");
        };
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return session;
    }

    private AdminAppUserResponse toResponse(AdminAppUserRow row) {
        int status = effectiveStatus(row);
        return new AdminAppUserResponse(
                row.getId(),
                safeText(row.getNickname()),
                safeText(row.getAvatar()),
                safeText(row.getEmail()),
                safeText(row.getPhone()),
                safeText(row.getPreferredRegion()),
                row.getGrowthValue(),
                row.getLevel(),
                row.getPoints(),
                status,
                statusText(status),
                formatDateTime(row.getLastLoginAt()),
                formatDateTime(row.getCreatedAt())
        );
    }

    private int effectiveStatus(AdminAppUserRow row) {
        if (Boolean.TRUE.equals(row.getIsDeleted())) {
            return STATUS_DELETED;
        }
        return row.getStatus() != null && row.getStatus() == STATUS_BANNED ? STATUS_BANNED : STATUS_NORMAL;
    }

    private String statusText(int status) {
        return switch (status) {
            case STATUS_BANNED -> "已封禁";
            case STATUS_DELETED -> "已注销";
            default -> "正常";
        };
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private String safeText(String value) {
        return value == null ? "" : value;
    }

    private String normalizeIp(String requestIp) {
        return StringUtils.hasText(requestIp) ? requestIp.trim() : "";
    }
}
