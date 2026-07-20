package com.tuowei.dazhongdianping.module.growth.model.response;
import com.tuowei.dazhongdianping.module.auth.model.GrowthRuleRow;
import com.tuowei.dazhongdianping.module.growth.model.LevelConfigRow;
import java.util.List;
public record GrowthConfigResponse(List<GrowthRuleRow> rules, List<LevelConfigRow> levels) {}
