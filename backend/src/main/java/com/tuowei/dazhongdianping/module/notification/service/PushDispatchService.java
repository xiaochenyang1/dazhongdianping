package com.tuowei.dazhongdianping.module.notification.service;

import com.tuowei.dazhongdianping.config.PushProperties;
import com.tuowei.dazhongdianping.common.push.PushProvider;
import com.tuowei.dazhongdianping.module.auth.mapper.UserGovernanceMapper;
import com.tuowei.dazhongdianping.module.auth.model.UserDeviceRow;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class PushDispatchService {
    private static final Logger LOGGER = LoggerFactory.getLogger(PushDispatchService.class);

    private final UserGovernanceMapper userGovernanceMapper;
    private final PushProperties properties;
    private final Map<Integer, PushProvider> providers;

    public PushDispatchService(UserGovernanceMapper userGovernanceMapper,
                               PushProperties properties,
                               List<PushProvider> providers) {
        this.userGovernanceMapper = userGovernanceMapper;
        this.properties = properties;
        this.providers = providers.stream().collect(Collectors.toUnmodifiableMap(
                PushProvider::channel,
                Function.identity()
        ));
    }

    @Async("pushTaskExecutor")
    public void dispatch(Long userId, PushMessage message) {
        dispatchNow(userId, message);
    }

    void dispatchNow(Long userId, PushMessage message) {
        if (!properties.isEnabled() || userId == null || message == null) {
            return;
        }
        for (UserDeviceRow device : userGovernanceMapper.selectPushDevicesByUserId(userId)) {
            PushProvider provider = providers.get(device.getPushChannel());
            if (provider == null || !provider.isConfigured() || !StringUtils.hasText(device.getPushToken())) {
                continue;
            }
            PushSendResult result = sendWithRetry(provider, device, message);
            if (result.invalidToken()) {
                userGovernanceMapper.deactivatePushToken(device.getId(), device.getPushToken());
                continue;
            }
            if (!result.success()) {
                LOGGER.warn("Push delivery failed provider={} deviceId={} errorCode={}",
                        result.provider(), device.getId(), result.errorCode());
            }
        }
    }

    private PushSendResult sendWithRetry(PushProvider provider, UserDeviceRow device, PushMessage message) {
        int maxAttempts = Math.max(1, Math.min(properties.getMaxAttempts(), 5));
        long backoffMillis = Math.max(0, Math.min(properties.getInitialBackoffMillis(), 10_000));
        PushSendResult result = PushSendResult.failed(provider.name(), "not_attempted");
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            result = provider.send(device, message);
            if (result.success() || result.invalidToken() || !result.retryable() || attempt == maxAttempts) {
                return result;
            }
            if (backoffMillis > 0) {
                try {
                    Thread.sleep(Math.min(backoffMillis << (attempt - 1), 30_000));
                } catch (InterruptedException interrupted) {
                    Thread.currentThread().interrupt();
                    return PushSendResult.failed(provider.name(), "interrupted");
                }
            }
        }
        return result;
    }
}
