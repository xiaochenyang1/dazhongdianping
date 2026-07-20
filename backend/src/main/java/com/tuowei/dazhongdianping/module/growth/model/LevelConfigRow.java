package com.tuowei.dazhongdianping.module.growth.model;
import java.time.LocalDateTime;
import lombok.Data;
@Data public class LevelConfigRow { private Integer level; private Integer minGrowth; private String levelName; private String icon; private String privilegeJson; private Boolean enabled; private LocalDateTime updatedAt; }
