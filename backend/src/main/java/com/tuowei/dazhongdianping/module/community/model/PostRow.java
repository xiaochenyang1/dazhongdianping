package com.tuowei.dazhongdianping.module.community.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class PostRow {
    private Long id;
    private Long userId;
    private Long circleId;
    private String circleName;
    private String region;
    private String userName;
    private String title;
    private String content;
    private Integer contentType;
    private Long shopId;
    private Long dealId;
    private Integer likeCount;
    private Integer commentCount;
    private Integer auditStatus;
    private String auditRemark;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
