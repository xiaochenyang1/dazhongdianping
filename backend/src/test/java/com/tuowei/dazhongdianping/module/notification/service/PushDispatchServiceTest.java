package com.tuowei.dazhongdianping.module.notification.service;

import com.tuowei.dazhongdianping.config.PushProperties;
import com.tuowei.dazhongdianping.common.push.PushProvider;
import com.tuowei.dazhongdianping.module.auth.mapper.UserGovernanceMapper;
import com.tuowei.dazhongdianping.module.auth.model.UserDeviceRow;
import java.lang.reflect.Proxy;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class PushDispatchServiceTest {

    @Test
    void shouldKeepPushDisabledWithoutCallingDeviceStore() {
        RecordingMapper recordingMapper = new RecordingMapper();
        PushProperties properties = new PushProperties();
        PushDispatchService service = new PushDispatchService(recordingMapper.proxy(), properties, List.of());

        service.dispatchNow(7L, message());

        assertEquals(0, recordingMapper.selectCalls);
    }

    @Test
    void shouldRetryTransientFailuresAndDeactivateOnlyTheInvalidToken() {
        RecordingMapper recordingMapper = new RecordingMapper();
        StubProvider provider = new StubProvider(1, "FCM",
                PushSendResult.retryable("FCM", "http_503"),
                PushSendResult.invalidToken("FCM", "UNREGISTERED"));
        PushProperties properties = new PushProperties();
        properties.setEnabled(true);
        properties.setMaxAttempts(3);
        properties.setInitialBackoffMillis(0);
        UserDeviceRow device = device(10L, 1, "stale-token");
        recordingMapper.devices = List.of(device);
        PushDispatchService service = new PushDispatchService(recordingMapper.proxy(), properties, List.of(provider));

        service.dispatchNow(7L, message());

        assertEquals(2, provider.calls);
        assertEquals(1, recordingMapper.deactivateCalls);
        assertEquals("stale-token", recordingMapper.deactivatedToken);
    }

    @Test
    void shouldLeaveSuccessfulTokensUntouched() {
        RecordingMapper recordingMapper = new RecordingMapper();
        PushProvider provider = new StubProvider(2, "APNs", PushSendResult.success("APNs"));
        PushProperties properties = new PushProperties();
        properties.setEnabled(true);
        recordingMapper.devices = List.of(device(10L, 2, "valid-token"));
        PushDispatchService service = new PushDispatchService(recordingMapper.proxy(), properties, List.of(provider));

        service.dispatchNow(7L, message());

        assertEquals(0, recordingMapper.deactivateCalls);
    }

    private PushMessage message() {
        return new PushMessage(99L, "review.like", "点评获赞", "有人赞了你的点评", "/reviews/9", "EU");
    }

    private UserDeviceRow device(Long id, int channel, String token) {
        UserDeviceRow row = new UserDeviceRow();
        row.setId(id);
        row.setPushChannel(channel);
        row.setPushToken(token);
        return row;
    }

    private static final class StubProvider implements PushProvider {
        private final int channel;
        private final String name;
        private final PushSendResult[] results;
        private int calls;

        private StubProvider(int channel, String name, PushSendResult... results) {
            this.channel = channel;
            this.name = name;
            this.results = results;
        }

        @Override
        public int channel() {
            return channel;
        }

        @Override
        public String name() {
            return name;
        }

        @Override
        public boolean isConfigured() {
            return true;
        }

        @Override
        public PushSendResult send(UserDeviceRow device, PushMessage message) {
            PushSendResult result = results[Math.min(calls, results.length - 1)];
            calls++;
            return result;
        }
    }

    private static final class RecordingMapper {
        private List<UserDeviceRow> devices = List.of();
        private int selectCalls;
        private int deactivateCalls;
        private String deactivatedToken;

        private UserGovernanceMapper proxy() {
            return (UserGovernanceMapper) Proxy.newProxyInstance(
                    UserGovernanceMapper.class.getClassLoader(),
                    new Class<?>[]{UserGovernanceMapper.class},
                    (ignored, method, args) -> {
                        if ("selectPushDevicesByUserId".equals(method.getName())) {
                            selectCalls++;
                            return devices;
                        }
                        if ("deactivatePushToken".equals(method.getName())) {
                            deactivateCalls++;
                            deactivatedToken = (String) args[1];
                            return 1;
                        }
                        if (method.getReturnType() == int.class) return 0;
                        if (method.getReturnType() == long.class) return 0L;
                        if (method.getReturnType() == boolean.class) return false;
                        if (List.class.isAssignableFrom(method.getReturnType())) return List.of();
                        return null;
                    }
            );
        }
    }
}
