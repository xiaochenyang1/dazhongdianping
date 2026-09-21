package com.tuowei.dazhongdianping.common.riskcontrol;

import java.util.List;

/**
 * 风控信号源：规则实现通过它读取评估所需的聚合数据，
 * 由 module.riskcontrol 提供 Mapper 支撑的实现类，规则本身保持无状态可测试。
 */
public interface RiskSignalSource {

    /**
     * 统计某用户在指定场景、时间窗口内的行为次数（不含当前这次）。
     *
     * @param region        区域
     * @param userId        用户 id
     * @param scene         场景
     * @param windowSeconds 时间窗口秒数，0 表示不限窗口（累计全部）
     * @return 次数
     */
    int countUserActions(String region, Long userId, RiskScene scene, int windowSeconds);

    /**
     * 某设备累计关联的独立用户数（多账号共享设备信号）。
     */
    int countDeviceUsers(String region, String fingerprint);

    /**
     * 该设备是否已被拉黑。
     */
    boolean isDeviceBlocked(String region, String fingerprint);

    /**
     * 拉取某用户最近的历史文本（如点评内容），用于相似度比对。
     *
     * @param limit 最多返回条数
     */
    List<String> recentUserContents(String region, Long userId, RiskScene scene, int limit);
}
