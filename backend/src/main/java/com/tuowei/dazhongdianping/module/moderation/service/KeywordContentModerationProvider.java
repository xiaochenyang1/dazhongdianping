package com.tuowei.dazhongdianping.module.moderation.service;

import com.tuowei.dazhongdianping.common.moderation.ContentModerationProvider;
import com.tuowei.dazhongdianping.common.moderation.ModerationDecision;
import com.tuowei.dazhongdianping.common.moderation.ModerationResult;
import java.util.List;
import org.springframework.stereotype.Service;

/** 关键词机审：命中现有敏感词即 BLOCK，未命中 PASS，不写命中行。 */
@Service
public class KeywordContentModerationProvider implements ContentModerationProvider {

    static final String PROVIDER = "keyword";

    private final SensitiveWordFilterService sensitiveWordFilterService;

    public KeywordContentModerationProvider(SensitiveWordFilterService sensitiveWordFilterService) {
        this.sensitiveWordFilterService = sensitiveWordFilterService;
    }

    @Override
    public ModerationResult moderate(String region, String... texts) {
        List<String> hits = sensitiveWordFilterService.findHits(region, texts);
        if (hits.isEmpty()) {
            return ModerationResult.pass(PROVIDER);
        }
        return new ModerationResult(
                ModerationDecision.BLOCK,
                "命中敏感词：" + String.join("、", hits),
                PROVIDER);
    }
}
