package com.tuowei.dazhongdianping.module.community.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PostCommentRow {
    private Long id;
    private Long postId;
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
