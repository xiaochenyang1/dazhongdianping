package com.tuowei.dazhongdianping.module.admin.activity.model;

import lombok.Data;

@Data
public class AdminOperationActivityItemRow {

    private Long id;
    private Long activityId;
    private Integer targetType;
    private Long targetId;
    private String targetName;
    private String title;
    private String subtitle;
    private String image;
    private Integer sort;
    private String extraJson;
    private Integer status;
}
