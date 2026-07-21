package com.tuowei.dazhongdianping.module.admin.banner.model;

import lombok.Data;

@Data
public class AdminBannerRow {

    private Long id;
    private Long cityId;
    private String cityName;
    private String region;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String linkUrl;
    private Boolean enabled;
    private Integer sortNo;
}
