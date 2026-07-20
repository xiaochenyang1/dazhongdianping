package com.tuowei.dazhongdianping.module.auth.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.mapper.UserGovernanceMapper;
import com.tuowei.dazhongdianping.module.auth.model.UserDeviceRow;
import com.tuowei.dazhongdianping.module.auth.model.UserPolicyAcceptLogRow;
import com.tuowei.dazhongdianping.module.auth.model.request.PolicyAcceptRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserDevicePushTokenUpdateRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserDeviceRegisterRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.PolicyAcceptLogResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.UserDeviceResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class UserGovernanceService {
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final UserGovernanceMapper userGovernanceMapper;

    public UserGovernanceService(UserGovernanceMapper userGovernanceMapper) {
        this.userGovernanceMapper = userGovernanceMapper;
    }

    @Transactional
    public PolicyAcceptLogResponse acceptPolicy(PolicyAcceptRequest request, String requestIp, String userAgent) {
        UserPolicyAcceptLogRow row = new UserPolicyAcceptLogRow();
        row.setUserId(currentUserId());
        row.setPolicyType(request.getPolicyType());
        row.setVersion(request.getVersion().trim());
        row.setLocale(request.getLocale().trim());
        row.setSource(request.getSource());
        row.setRequestIp(truncate(requestIp, 45));
        row.setUserAgent(truncate(userAgent, 255));
        userGovernanceMapper.insertPolicyAcceptLog(row);
        return toPolicyResponse(userGovernanceMapper.selectPolicyAcceptLogsByUserId(row.getUserId()).stream()
                .filter(item -> item.getId().equals(row.getId()))
                .findFirst()
                .orElse(row));
    }

    public List<PolicyAcceptLogResponse> listPolicyAcceptLogs() {
        return userGovernanceMapper.selectPolicyAcceptLogsByUserId(currentUserId()).stream()
                .map(this::toPolicyResponse)
                .toList();
    }

    @Transactional
    public UserDeviceResponse registerDevice(UserDeviceRegisterRequest request) {
        validatePushToken(request.getPushChannel(), request.getPushToken());
        Long userId = currentUserId();
        String deviceUid = request.getDeviceUid().trim();
        UserDeviceRow row = userGovernanceMapper.selectDeviceByUidForUpdate(deviceUid);
        if (row == null) {
            row = new UserDeviceRow();
            row.setUserId(userId);
            row.setDeviceUid(deviceUid);
            row.setPlatform(request.getPlatform());
            row.setPushChannel(request.getPushChannel());
            row.setPushToken(normalizeToken(request.getPushToken()));
            row.setAppVersion(request.getAppVersion().trim());
            row.setStatus(1);
            row.setLastActiveAt(LocalDateTime.now());
            userGovernanceMapper.insertDevice(row);
        } else {
            row.setUserId(userId);
            row.setPlatform(request.getPlatform());
            row.setPushChannel(request.getPushChannel());
            row.setPushToken(normalizeToken(request.getPushToken()));
            row.setAppVersion(request.getAppVersion().trim());
            row.setStatus(1);
            row.setLastActiveAt(LocalDateTime.now());
            userGovernanceMapper.updateDeviceRegistration(row);
        }
        return toDeviceResponse(requireDevice(row.getId(), userId));
    }

    public List<UserDeviceResponse> listDevices() {
        return userGovernanceMapper.selectDevicesByUserId(currentUserId()).stream()
                .map(this::toDeviceResponse)
                .toList();
    }

    @Transactional
    public UserDeviceResponse updatePushToken(Long deviceId, UserDevicePushTokenUpdateRequest request) {
        validatePushToken(request.getPushChannel(), request.getPushToken());
        Long userId = currentUserId();
        UserDeviceRow row = requireDevice(deviceId, userId);
        row.setPushChannel(request.getPushChannel());
        row.setPushToken(normalizeToken(request.getPushToken()));
        row.setAppVersion(request.getAppVersion().trim());
        row.setLastActiveAt(LocalDateTime.now());
        if (userGovernanceMapper.updateDevicePushToken(row) != 1) {
            throw new IllegalArgumentException("设备推送信息更新失败");
        }
        return toDeviceResponse(requireDevice(deviceId, userId));
    }

    @Transactional
    public UserDeviceResponse logoutDevice(Long deviceId) {
        Long userId = currentUserId();
        requireDevice(deviceId, userId);
        if (userGovernanceMapper.logoutDevice(deviceId, userId) != 1) {
            throw new IllegalArgumentException("设备登出失败");
        }
        return toDeviceResponse(requireDevice(deviceId, userId));
    }

    private UserDeviceRow requireDevice(Long deviceId, Long userId) {
        UserDeviceRow row = userGovernanceMapper.selectDeviceByIdAndUserId(deviceId, userId);
        if (row == null) {
            throw new NotFoundException("设备不存在");
        }
        return row;
    }

    private Long currentUserId() {
        UserSession session = UserSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return session.userId();
    }

    private void validatePushToken(Integer pushChannel, String pushToken) {
        if (pushChannel != null && pushChannel > 0 && !StringUtils.hasText(pushToken)) {
            throw new IllegalArgumentException("启用推送渠道时 pushToken 不能为空");
        }
    }

    private String normalizeToken(String value) {
        return value == null ? "" : value.trim();
    }

    private String truncate(String value, int maxLength) {
        String normalized = value == null ? "" : value.trim();
        return normalized.length() <= maxLength ? normalized : normalized.substring(0, maxLength);
    }

    private PolicyAcceptLogResponse toPolicyResponse(UserPolicyAcceptLogRow row) {
        return new PolicyAcceptLogResponse(
                row.getId(),
                row.getPolicyType(),
                row.getVersion(),
                row.getLocale(),
                row.getSource(),
                row.getRequestIp(),
                row.getUserAgent(),
                formatDateTime(row.getAcceptedAt())
        );
    }

    private UserDeviceResponse toDeviceResponse(UserDeviceRow row) {
        return new UserDeviceResponse(
                row.getId(),
                row.getDeviceUid(),
                row.getPlatform(),
                row.getPushChannel(),
                StringUtils.hasText(row.getPushToken()),
                row.getAppVersion(),
                row.getStatus(),
                formatDateTime(row.getLastActiveAt()),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? null : value.format(DATE_TIME_FORMATTER);
    }
}
