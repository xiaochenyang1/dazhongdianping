package com.tuowei.dazhongdianping.module.review.model.request;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import lombok.Data;

@Data
public class ReviewSaveRequest {

    @NotNull(message = "shopId 不能为空")
    private Long shopId;

    @NotBlank(message = "content 不能为空")
    @Size(max = 500, message = "content 不能超过 500 字")
    private String content;

    @NotNull(message = "scoreOverall 不能为空")
    @DecimalMin(value = "1.0", message = "scoreOverall 不能小于 1")
    @DecimalMax(value = "5.0", message = "scoreOverall 不能大于 5")
    private BigDecimal scoreOverall;

    @NotNull(message = "scoreTaste 不能为空")
    @DecimalMin(value = "1.0", message = "scoreTaste 不能小于 1")
    @DecimalMax(value = "5.0", message = "scoreTaste 不能大于 5")
    private BigDecimal scoreTaste;

    @NotNull(message = "scoreEnv 不能为空")
    @DecimalMin(value = "1.0", message = "scoreEnv 不能小于 1")
    @DecimalMax(value = "5.0", message = "scoreEnv 不能大于 5")
    private BigDecimal scoreEnv;

    @NotNull(message = "scoreService 不能为空")
    @DecimalMin(value = "1.0", message = "scoreService 不能小于 1")
    @DecimalMax(value = "5.0", message = "scoreService 不能大于 5")
    private BigDecimal scoreService;

    @NotNull(message = "cost 不能为空")
    @DecimalMin(value = "0.0", message = "cost 不能小于 0")
    private BigDecimal cost;

    private String currency = "CNY";

    @Size(max = 10, message = "tags 最多 10 个")
    private List<String> tags = List.of();

    @Size(max = 9, message = "images 最多 9 张")
    private List<String> images = List.of();
}
