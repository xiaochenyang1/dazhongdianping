package com.tuowei.dazhongdianping.module.riskcontrol.model.response;

/**
 * 风控事件视图（Admin 看板/处置）。
 */
public record RiskEventResponse(
        Long id,
        String region,
        String scene,
        Long userId,
        String deviceFingerprint,
        String ip,
        Long bizId,
        int riskScore,
        int decision,
        String hitRules,
        String reason,
        int disposeStatus,
        String disposeRemark,
        Long disposedBy,
        String disposedAt,
        String createdAt
) {
}
