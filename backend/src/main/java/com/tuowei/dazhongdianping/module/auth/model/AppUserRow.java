package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AppUserRow {

    private Long id;
    private String nickname;
    private String avatar;
    private String email;
    private String phone;
    private String passwordHash;
    private Integer gender;
    private String signature;
    private String preferredRegion;
    private Integer growthValue;
    private Integer level;
    private Integer points;
    private Integer status;
    private LocalDateTime lastLoginAt;
}
