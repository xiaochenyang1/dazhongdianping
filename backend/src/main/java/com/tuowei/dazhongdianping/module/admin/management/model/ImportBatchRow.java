package com.tuowei.dazhongdianping.module.admin.management.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ImportBatchRow {
    private Long id;
    private Long adminId;
    private String region;
    private String fileName;
    private Integer total;
    private Integer success;
    private Integer failed;
    private Integer status;
    private String errorFile;
    private LocalDateTime createdAt;
}
