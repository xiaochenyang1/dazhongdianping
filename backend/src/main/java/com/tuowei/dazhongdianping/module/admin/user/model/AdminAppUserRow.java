package com.tuowei.dazhongdianping.module.admin.user.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class AdminAppUserRow {
    private Long id;
    private String nickname;
    private String avatar;
    private String email;
    private String phone;
    private Integer gender;
    private String signature;
    private String preferredRegion;
    private Integer growthValue;
    private Integer level;
    private Integer points;
    private Integer status;
    private Boolean isDeleted;
    private LocalDateTime lastLoginAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
