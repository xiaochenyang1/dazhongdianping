package com.tuowei.dazhongdianping.module.riskcontrol.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.riskcontrol.mapper.RiskMapper;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskEventQuery;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskEventRow;
import com.tuowei.dazhongdianping.module.riskcontrol.model.RiskRuleRow;
import com.tuowei.dazhongdianping.module.riskcontrol.model.request.RiskEventDisposeRequest;
import com.tuowei.dazhongdianping.module.riskcontrol.model.request.RiskRuleUpdateRequest;
import com.tuowei.dazhongdianping.module.riskcontrol.model.response.RiskEventResponse;
import com.tuowei.dazhongdianping.module.riskcontrol.model.response.RiskRuleResponse;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Admin 侧风控管理：事件看板/处置 + 规则查询/更新，按当前区域隔离。
 */
@Service
public class AdminRiskService {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final RiskMapper riskMapper;

    public AdminRiskService(RiskMapper riskMapper) {
        this.riskMapper = riskMapper;
    }

    public PageResult<RiskEventResponse> listEvents(String scene, Integer decision,
                                                    Integer disposeStatus, int page, int pageSize) {
        String region = RegionContext.getRegion().name();
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(pageSize, 1), 100);

        RiskEventQuery query = new RiskEventQuery();
        query.setRegion(region);
        query.setScene(scene);
        query.setDecision(decision);
        query.setDisposeStatus(disposeStatus);
        query.setOffset((safePage - 1) * safeSize);
        query.setLimit(safeSize);

        long total = riskMapper.countEvents(query);
        List<RiskEventResponse> list = riskMapper.selectEvents(query).stream()
                .map(this::toEventResponse)
                .toList();
        boolean hasMore = (long) safePage * safeSize < total;
        return new PageResult<>(list, total, safePage, safeSize, hasMore);
    }

    @Transactional
    public RiskEventResponse disposeEvent(Long id, RiskEventDisposeRequest request) {
        String region = RegionContext.getRegion().name();
        RiskEventRow existing = riskMapper.selectEventById(id, region);
        if (existing == null) {
            throw new NotFoundException("风控事件不存在");
        }
        AdminSession session = AdminSessionContext.get();
        Long adminId = session == null ? null : session.adminId();
        riskMapper.disposeEvent(id, region, request.getDisposeStatus(),
                request.getDisposeRemark() == null ? "" : request.getDisposeRemark(), adminId);
        return toEventResponse(riskMapper.selectEventById(id, region));
    }

    public List<RiskRuleResponse> listRules() {
        String region = RegionContext.getRegion().name();
        return riskMapper.selectRules(region).stream()
                .map(this::toRuleResponse)
                .toList();
    }

    @Transactional
    public RiskRuleResponse updateRule(Long id, RiskRuleUpdateRequest request) {
        String region = RegionContext.getRegion().name();
        RiskRuleRow existing = riskMapper.selectRuleById(id, region);
        if (existing == null) {
            throw new NotFoundException("风控规则不存在");
        }
        existing.setAction(request.getAction());
        existing.setThreshold(request.getThreshold());
        existing.setWindowSeconds(request.getWindowSeconds());
        existing.setRiskScore(request.getRiskScore());
        existing.setEnabled(request.getEnabled());
        existing.setRemark(request.getRemark() == null ? "" : request.getRemark());
        riskMapper.updateRule(existing);
        return toRuleResponse(riskMapper.selectRuleById(id, region));
    }

    private RiskEventResponse toEventResponse(RiskEventRow row) {
        return new RiskEventResponse(
                row.getId(),
                row.getRegion(),
                row.getScene(),
                row.getUserId(),
                row.getDeviceFingerprint(),
                row.getIp(),
                row.getBizId(),
                row.getRiskScore() == null ? 0 : row.getRiskScore(),
                row.getDecision() == null ? 1 : row.getDecision(),
                row.getHitRules() == null ? "" : row.getHitRules(),
                row.getReason() == null ? "" : row.getReason(),
                row.getDisposeStatus() == null ? 0 : row.getDisposeStatus(),
                row.getDisposeRemark() == null ? "" : row.getDisposeRemark(),
                row.getDisposedBy(),
                row.getDisposedAt() == null ? null : row.getDisposedAt().format(FORMATTER),
                row.getCreatedAt() == null ? null : row.getCreatedAt().format(FORMATTER)
        );
    }

    private RiskRuleResponse toRuleResponse(RiskRuleRow row) {
        return new RiskRuleResponse(
                row.getId(),
                row.getRegion(),
                row.getRuleCode(),
                row.getName(),
                row.getScene(),
                row.getAction() == null ? 2 : row.getAction(),
                row.getThreshold() == null ? 0 : row.getThreshold(),
                row.getWindowSeconds() == null ? 0 : row.getWindowSeconds(),
                row.getRiskScore() == null ? 0 : row.getRiskScore(),
                Boolean.TRUE.equals(row.getEnabled()),
                row.getRemark() == null ? "" : row.getRemark()
        );
    }
}
