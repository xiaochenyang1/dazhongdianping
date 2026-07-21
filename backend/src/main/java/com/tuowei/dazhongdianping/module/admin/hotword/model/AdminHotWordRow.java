package com.tuowei.dazhongdianping.module.admin.hotword.model;

import lombok.Data;

@Data
public class AdminHotWordRow {

    private Long id;
    private String region;
    private String keyword;
    private Boolean enabled;
    private Integer sortNo;
}
