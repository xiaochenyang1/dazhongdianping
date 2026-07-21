package com.tuowei.dazhongdianping.module.admin.geodata.model;

import lombok.Data;

@Data
public class AdminAreaRow {
    private Long id;
    private Long cityId;
    private String region;
    private String name;
    private Integer sortNo;
    private Integer status;
}
