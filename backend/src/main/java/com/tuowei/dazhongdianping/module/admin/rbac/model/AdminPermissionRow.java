package com.tuowei.dazhongdianping.module.admin.rbac.model;

public class AdminPermissionRow {
    private Long id;
    private String code;
    private String name;
    private String category;
    private Integer permissionType;
    private Integer status;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Integer getPermissionType() { return permissionType; }
    public void setPermissionType(Integer permissionType) { this.permissionType = permissionType; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
}
