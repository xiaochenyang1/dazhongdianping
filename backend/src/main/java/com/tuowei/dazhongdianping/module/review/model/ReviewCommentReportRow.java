package com.tuowei.dazhongdianping.module.review.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ReviewCommentReportRow {

    private Long id;
    private Long reviewId;
    private Long commentId;
    private Long reporterUserId;
    private String reporterUserName;
    private String reason;
    private Integer status;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
