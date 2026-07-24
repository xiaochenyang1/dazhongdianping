package com.tuowei.dazhongdianping.module.moderation.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class SensitiveWordRow {
    private Long id;
    private String region;
    private String word;
    private Integer matchMode;
    private Boolean enabled;
    private String remark;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
