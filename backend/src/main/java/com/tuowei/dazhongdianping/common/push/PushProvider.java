package com.tuowei.dazhongdianping.common.push;

import com.tuowei.dazhongdianping.module.auth.model.UserDeviceRow;
import com.tuowei.dazhongdianping.module.notification.service.PushMessage;
import com.tuowei.dazhongdianping.module.notification.service.PushSendResult;

public interface PushProvider {

    int channel();

    String name();

    boolean isConfigured();

    PushSendResult send(UserDeviceRow device, PushMessage message);
}
