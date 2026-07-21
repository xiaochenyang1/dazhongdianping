package com.tuowei.dazhongdianping.module.community.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PostRepostRow {
    private Long id;
    private Long postId;
    private Long userId;
    private String region;
    private String postTitle;
    private Long postUserId;
    private String postUserName;
    private LocalDateTime createdAt;
}
