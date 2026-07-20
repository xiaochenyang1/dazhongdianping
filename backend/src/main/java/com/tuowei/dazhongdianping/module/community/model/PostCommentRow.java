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
    private LocalDateTime createdAt;
}
