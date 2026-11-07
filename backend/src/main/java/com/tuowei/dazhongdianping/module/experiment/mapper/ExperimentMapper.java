package com.tuowei.dazhongdianping.module.experiment.mapper;

import com.tuowei.dazhongdianping.module.experiment.model.ExperimentAssignmentRow;
import com.tuowei.dazhongdianping.module.experiment.model.ExperimentRow;
import com.tuowei.dazhongdianping.module.experiment.model.FeatureFlagRow;
import com.tuowei.dazhongdianping.module.experiment.model.FeatureFlagScopeRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ExperimentMapper {

    List<FeatureFlagRow> selectFlags(@Param("region") String region);

    FeatureFlagRow selectFlag(@Param("id") Long id, @Param("region") String region);

    FeatureFlagRow selectFlagByKey(@Param("region") String region, @Param("flagKey") String flagKey);

    void insertFlag(FeatureFlagRow row);

    int updateFlag(FeatureFlagRow row);

    List<FeatureFlagScopeRow> selectFlagScopes(@Param("featureFlagId") Long featureFlagId);

    FeatureFlagScopeRow selectFlagScope(@Param("id") Long id, @Param("featureFlagId") Long featureFlagId);

    FeatureFlagScopeRow selectFlagScopeByTarget(
            @Param("featureFlagId") Long featureFlagId,
            @Param("scopeType") String scopeType,
            @Param("scopeId") Long scopeId);

    FeatureFlagScopeRow selectEffectiveFlagScope(
            @Param("featureFlagId") Long featureFlagId,
            @Param("campaignId") Long campaignId,
            @Param("shopId") Long shopId);

    void insertFlagScope(FeatureFlagScopeRow row);

    int updateFlagScope(FeatureFlagScopeRow row);

    int deleteFlagScope(@Param("id") Long id, @Param("featureFlagId") Long featureFlagId);

    List<ExperimentRow> selectExperiments(@Param("region") String region);

    ExperimentRow selectExperiment(@Param("id") Long id, @Param("region") String region);

    void insertExperiment(ExperimentRow row);

    ExperimentAssignmentRow selectAssignment(
            @Param("experimentId") Long experimentId, @Param("userId") Long userId);

    void insertAssignment(ExperimentAssignmentRow row);
}
