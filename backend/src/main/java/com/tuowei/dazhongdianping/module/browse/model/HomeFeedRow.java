package com.tuowei.dazhongdianping.module.browse.model;

import lombok.Data;

@Data
public class HomeFeedRow {
    private Long id;
    private String type;
    private String title;
    private String subtitle;
    private String coverUrl;
    private Long shopId;
    private Integer sortNo;
}
