package com.tuowei.dazhongdianping.module.admin.geodata.model;

import lombok.Data;

@Data
public class AdminCityRow {
    private Long id;
    private String code;
    private String region;
    private String name;
    private Integer sortNo;
    private Integer status;
}
