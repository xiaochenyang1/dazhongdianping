package com.tuowei.dazhongdianping.module.community.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PostReportRow {
    private Long id;
    private Long postId;
    private Long reporterUserId;
    private String reporterUserName;
    private String reason;
    private Integer status;
    private LocalDateTime createdAt;
}
