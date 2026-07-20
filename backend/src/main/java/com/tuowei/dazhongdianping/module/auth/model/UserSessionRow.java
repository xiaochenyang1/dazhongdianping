package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class UserSessionRow {

    private Long id;
    private Long userId;
    private String refreshTokenHash;
    private Integer status;
    private LocalDateTime refreshExpireAt;
}
