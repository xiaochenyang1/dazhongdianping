package com.tuowei.dazhongdianping.module.review.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class ReviewCommentRow {

    private Long id;
    private Long reviewId;
    private Long userId;
    private String userName;
    private String content;
    private Long parentId;
    private Long replyTo;
    private Long replyToUserId;
    private String replyToUserName;
    private String replyToContent;
    private Integer status;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
