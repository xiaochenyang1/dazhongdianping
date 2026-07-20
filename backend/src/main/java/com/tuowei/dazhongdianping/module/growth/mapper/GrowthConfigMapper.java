package com.tuowei.dazhongdianping.module.growth.mapper;
import com.tuowei.dazhongdianping.module.auth.model.GrowthRuleRow;
import com.tuowei.dazhongdianping.module.growth.model.LevelConfigRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
@Mapper public interface GrowthConfigMapper { List<GrowthRuleRow> selectRules(); List<LevelConfigRow> selectLevels(); LevelConfigRow selectLevel(@Param("level") Integer level); int updateLevel(LevelConfigRow row); GrowthRuleRow selectRule(@Param("id") Long id); GrowthRuleRow selectRuleByAction(@Param("action") String action); void insertRule(GrowthRuleRow row); int updateRule(GrowthRuleRow row); }
