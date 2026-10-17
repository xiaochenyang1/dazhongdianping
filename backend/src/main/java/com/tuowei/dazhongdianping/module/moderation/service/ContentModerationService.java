package com.tuowei.dazhongdianping.module.moderation.service;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.moderation.ContentModerationProvider;
import com.tuowei.dazhongdianping.common.moderation.ModerationDecision;
import com.tuowei.dazhongdianping.common.moderation.ModerationResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.moderation.mapper.AutomodHitMapper;
import com.tuowei.dazhongdianping.module.moderation.model.AutomodHitQuery;
import com.tuowei.dazhongdianping.module.moderation.model.AutomodHitRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class ContentModerationService {

    private static final int REASON_MAX = 255;

    private final ContentModerationProvider provider;
    private final AutomodHitMapper mapper;
    private final AutomodHitWriter hitWriter;

    public ContentModerationService(
            ContentModerationProvider provider,
            AutomodHitMapper mapper,
            AutomodHitWriter hitWriter) {
        this.provider = provider;
        this.mapper = mapper;
        this.hitWriter = hitWriter;
    }

    /**
     * 调用机审提供者。BLOCK / REVIEW 写入 automod_hit；BLOCK 拒绝内容。
     * PASS 不插行。bizId 在业务插入前可为 0。
     */
    public ModerationDecision moderate(String region, String bizType, long bizId, long userId, String... texts) {
        return moderateForAuditRegion(region, region, bizType, bizId, userId, texts);
    }

    public ModerationDecision moderateForAuditRegion(
            String region,
            String auditRegion,
            String bizType,
            long bizId,
            long userId,
            String... texts) {
        ModerationResult result = provider.moderate(region, texts);
        if (result == null || result.decision() == null) {
            throw new IllegalStateException("内容机审未返回有效结论");
        }
        if (result.decision() == ModerationDecision.PASS) {
            return ModerationDecision.PASS;
        }
        AutomodHitRow row = new AutomodHitRow();
        row.setRegion(auditRegion);
        row.setBizType(bizType);
        row.setBizId(bizId);
        row.setUserId(userId);
        row.setDecision(result.decision().code());
        row.setProvider(result.provider() == null ? "" : result.provider());
        row.setReason(truncate(result.reason()));
        hitWriter.record(row);
        if (result.decision() == ModerationDecision.BLOCK) {
            String reason = result.reason();
            if (reason == null || reason.isBlank()) {
                throw new IllegalArgumentException("内容未通过机审");
            }
            throw new IllegalArgumentException("内容未通过机审：" + reason);
        }
        return result.decision();
    }

    public PageResult<Map<String, Object>> listHits(AutomodHitQuery query) {
        if (query == null) {
            query = new AutomodHitQuery();
        }
        query.normalize();
        String region = RegionContext.getRegion().name();
        long total = mapper.countHits(region, query.getDecision());
        List<Map<String, Object>> list = mapper.selectHits(
                        region, query.getDecision(), query.getPageSize(), query.getOffset())
                .stream()
                .map(this::toMap)
                .toList();
        return new PageResult<>(list, total, query.getPage(), query.getPageSize(),
                query.getOffset() + list.size() < total);
    }

    private Map<String, Object> toMap(AutomodHitRow row) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("bizType", row.getBizType());
        map.put("bizId", row.getBizId());
        map.put("userId", row.getUserId());
        map.put("decision", row.getDecision());
        map.put("provider", row.getProvider());
        map.put("reason", row.getReason());
        map.put("createdAt", row.getCreatedAt());
        return map;
    }

    private String truncate(String reason) {
        if (reason == null) {
            return "";
        }
        return reason.length() <= REASON_MAX ? reason : reason.substring(0, REASON_MAX);
    }
}
