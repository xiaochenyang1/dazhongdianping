package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PrivacyExportTaskRow {

    private Long id;
    private Long userId;
    private String scopeJson;
    private String format;
    private Integer status;
    private String fileName;
    private String filePath;
    private LocalDateTime expireAt;
    private String failReason;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
