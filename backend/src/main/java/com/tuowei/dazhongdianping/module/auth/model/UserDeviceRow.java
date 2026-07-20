package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class UserDeviceRow {
    private Long id;
    private Long userId;
    private String deviceUid;
    private Integer platform;
    private Integer pushChannel;
    private String pushToken;
    private String appVersion;
    private Integer status;
    private LocalDateTime lastActiveAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
