package com.tuowei.dazhongdianping.module.auth.model.request;

import jakarta.validation.constraints.Size;
import java.util.List;
import lombok.Data;

@Data
public class PrivacyExportTaskCreateRequest {

    @Size(max = 8, message = "modules 最多 8 个")
    private List<String> modules;

    @Size(max = 16, message = "format 不能超过 16 字")
    private String format;
}
