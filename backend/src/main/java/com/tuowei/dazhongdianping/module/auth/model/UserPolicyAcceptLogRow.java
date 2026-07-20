package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class UserPolicyAcceptLogRow {
    private Long id;
    private Long userId;
    private Integer policyType;
    private String version;
    private String locale;
    private Integer source;
    private String requestIp;
    private String userAgent;
    private LocalDateTime acceptedAt;
}
