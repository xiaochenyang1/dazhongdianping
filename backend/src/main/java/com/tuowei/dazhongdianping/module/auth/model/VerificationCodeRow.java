package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class VerificationCodeRow {

    private Long id;
    private String scene;
    private Integer targetType;
    private String target;
    private String codeHash;
    private String deviceId;
    private String requestIp;
    private Integer status;
    private LocalDateTime expireAt;
}
