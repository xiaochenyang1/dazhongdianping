package com.tuowei.dazhongdianping.module.riskcontrol.mapper;

import com.tuowei.dazhongdianping.module.riskcontrol.model.DeviceFingerprintRow;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskEventQuery;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskEventRow;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskRuleRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface RiskMapper {

    // ---------- 规则 ----------

    /** 拉取某区域某场景下启用的规则。 */
    List<RiskRuleRow> selectEnabledRules(@Param("region") String region, @Param("scene") String scene);

    /** 拉取某区域全部规则（Admin 管理用）。 */
    List<RiskRuleRow> selectRules(@Param("region") String region);

    RiskRuleRow selectRuleById(@Param("id") Long id, @Param("region") String region);

    int updateRule(RiskRuleRow row);

    // ---------- 事件 ----------

    void insertEvent(RiskEventRow row);

    List<RiskEventRow> selectEvents(RiskEventQuery query);

    long countEvents(RiskEventQuery query);

    RiskEventRow selectEventById(@Param("id") Long id, @Param("region") String region);

    int disposeEvent(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("disposeStatus") Integer disposeStatus,
            @Param("disposeRemark") String disposeRemark,
            @Param("disposedBy") Long disposedBy
    );

    // ---------- 信号 ----------

    /** 统计用户在窗口内某场景行为次数（windowSeconds=0 表示不限窗口）。 */
    int countUserActions(
            @Param("region") String region,
            @Param("userId") Long userId,
            @Param("scene") String scene,
            @Param("windowSeconds") int windowSeconds
    );

    /** 拉取用户最近的点评文本，用于相似度比对。 */
    List<String> selectRecentReviewContents(
            @Param("region") String region,
            @Param("userId") Long userId,
            @Param("limit") int limit
    );

    // ---------- 设备指纹 ----------

    DeviceFingerprintRow selectDevice(@Param("region") String region, @Param("fingerprint") String fingerprint);

    void insertDevice(
            @Param("region") String region,
            @Param("fingerprint") String fingerprint,
            @Param("userId") Long userId
    );

    /** 已存在设备时更新最后使用信息；newUser=true 时同时累加独立用户数。 */
    void updateDeviceSeen(
            @Param("region") String region,
            @Param("fingerprint") String fingerprint,
            @Param("userId") Long userId,
            @Param("newUser") boolean newUser
    );

    /** 命中风控时累加该设备命中计数。 */
    void incrementDeviceRiskHit(@Param("region") String region, @Param("fingerprint") String fingerprint);
}
