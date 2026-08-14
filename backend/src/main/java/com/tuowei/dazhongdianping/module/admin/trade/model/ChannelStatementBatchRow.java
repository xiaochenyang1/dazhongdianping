package com.tuowei.dazhongdianping.module.admin.trade.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ChannelStatementBatchRow {
    private Long id;
    private Long adminId;
    private String region;
    private String channel;
    private String fileName;
    private String fileSha256;
    private Integer totalRows;
    private Integer matchedRows;
    private Integer discrepancyRows;
    private Integer unmatchedRows;
    private Integer invalidRows;
    private Integer ignoredRows;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
