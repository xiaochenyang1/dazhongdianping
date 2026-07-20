package com.tuowei.dazhongdianping.module.admin.management.model.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;
import lombok.Data;

@Data
public class AdminImportShopsRequest {

    @NotBlank(message = "fileName 不能为空")
    private String fileName;

    @NotBlank(message = "region 不能为空")
    private String region;

    @Valid
    @NotEmpty(message = "records 不能为空")
    @Size(max = 200, message = "单次导入最多 200 条")
    private List<AdminImportShopRecordRequest> records;
}
