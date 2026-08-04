package com.tuowei.dazhongdianping.module.community.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PostCommentReportRow {

    private Long id;
    private Long postId;
    private Long commentId;
    private Long reporterUserId;
    private String reporterUserName;
    private String reason;
    private Integer status;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
