package com.tuowei.dazhongdianping.module.admin.geodata.model;

import lombok.Data;

@Data
public class AdminCategoryRow {
    private Long id;
    private Long parentId;
    private String region;
    private String name;
    private Integer sortNo;
    private Integer status;
}
