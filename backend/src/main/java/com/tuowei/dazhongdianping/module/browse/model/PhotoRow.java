package com.tuowei.dazhongdianping.module.browse.model;

import lombok.Data;

@Data
public class PhotoRow {
    private Long id;
    private Long shopId;
    private String imageUrl;
    private Integer sortNo;
}
