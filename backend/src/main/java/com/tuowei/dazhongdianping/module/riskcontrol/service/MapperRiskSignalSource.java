package com.tuowei.dazhongdianping.module.riskcontrol.service;

import com.tuowei.dazhongdianping.common.riskcontrol.RiskScene;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskSignalSource;
import com.tuowei.dazhongdianping.module.riskcontrol.mapper.RiskMapper;
import com.tuowei.dazhongdianping.module.riskcontrol.model.DeviceFingerprintRow;
import java.util.List;
import org.springframework.stereotype.Component;

/**
 * 基于 MyBatis Mapper 的风控信号源实现。规则通过它读取聚合数据，
 * 从而规则实现本身保持无状态、可用手写 Fake 单测。
 */
@Component
public class MapperRiskSignalSource implements RiskSignalSource {

    private final RiskMapper riskMapper;

    public MapperRiskSignalSource(RiskMapper riskMapper) {
        this.riskMapper = riskMapper;
    }

    @Override
    public int countUserActions(String region, Long userId, RiskScene scene, int windowSeconds) {
        if (userId == null) {
            return 0;
        }
        return riskMapper.countUserActions(region, userId, scene.code(), windowSeconds);
    }

    @Override
    public int countDeviceUsers(String region, String fingerprint) {
        DeviceFingerprintRow row = riskMapper.selectDevice(region, fingerprint);
        return row == null || row.getUserCount() == null ? 0 : row.getUserCount();
    }

    @Override
    public boolean isDeviceBlocked(String region, String fingerprint) {
        DeviceFingerprintRow row = riskMapper.selectDevice(region, fingerprint);
        return row != null && Boolean.TRUE.equals(row.getBlocked());
    }

    @Override
    public List<String> recentUserContents(String region, Long userId, RiskScene scene, int limit) {
        if (userId == null || scene != RiskScene.REVIEW_CREATE) {
            return List.of();
        }
        return riskMapper.selectRecentReviewContents(region, userId, limit);
    }
}
