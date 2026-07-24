package com.tuowei.dazhongdianping.module.activity.model;

import lombok.Data;

@Data
public class PublicActivityItemRow {

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
