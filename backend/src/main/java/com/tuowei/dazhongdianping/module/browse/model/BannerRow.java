package com.tuowei.dazhongdianping.module.browse.model;

import lombok.Data;

@Data
public class BannerRow {
    private Long id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String linkUrl;
    private Integer sortNo;
}
