package com.tuowei.dazhongdianping.module.rank.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.Map;
import lombok.Data;

@Data
public class RankConfigSaveRequest {
    @NotNull @Min(1) @Max(3) private Integer rankType;
    @NotBlank private String region;
    @NotNull private Long cityId;
    @NotNull private Long categoryId;
    @NotNull @Min(1) @Max(4) private Integer calcCycle;
    @NotEmpty private Map<String, BigDecimal> weight;
    @NotNull @Min(0) private Integer minReviewCount;
    @NotNull @DecimalMin("0") private BigDecimal minScore;
    private Boolean manualIntervene = Boolean.TRUE;
}
