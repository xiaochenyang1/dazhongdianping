package com.tuowei.dazhongdianping.common.riskcontrol.rule;

import com.tuowei.dazhongdianping.common.riskcontrol.RiskContext;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRule;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleConfig;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskRuleHit;
import com.tuowei.dazhongdianping.common.riskcontrol.RiskSignalSource;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 批量相似文本规则：将本次内容与该用户历史内容做相似度比对，
 * 相似度（百分比）达到阈值即命中，用于识别复制粘贴刷点评。
 * 相似度用字符二元组（bigram）的 Jaccard 系数近似，无需外部依赖。
 */
@Component
public class DuplicateContentRiskRule implements RiskRule {

    private static final int RECENT_LIMIT = 20;

    @Override
    public String code() {
        return "review_duplicate";
    }

    @Override
    public RiskRuleHit evaluate(RiskContext context, RiskRuleConfig config, RiskSignalSource signals) {
        if (context.userId() == null || !StringUtils.hasText(context.content()) || config.threshold() <= 0) {
            return RiskRuleHit.miss();
        }
        Set<String> current = bigrams(context.content());
        if (current.isEmpty()) {
            return RiskRuleHit.miss();
        }
        List<String> history = signals.recentUserContents(
                context.region(), context.userId(), context.scene(), RECENT_LIMIT);
        int best = 0;
        for (String past : history) {
            int similarity = similarityPercent(current, bigrams(past));
            if (similarity > best) {
                best = similarity;
            }
        }
        if (best >= config.threshold()) {
            return RiskRuleHit.hit(config,
                    "与历史内容相似度 " + best + "% 达到阈值 " + config.threshold() + "%");
        }
        return RiskRuleHit.miss();
    }

    private Set<String> bigrams(String text) {
        Set<String> grams = new HashSet<>();
        if (text == null) {
            return grams;
        }
        String normalized = text.replaceAll("\\s+", "").toLowerCase();
        if (normalized.length() < 2) {
            if (!normalized.isEmpty()) {
                grams.add(normalized);
            }
            return grams;
        }
        for (int i = 0; i < normalized.length() - 1; i++) {
            grams.add(normalized.substring(i, i + 2));
        }
        return grams;
    }

    private int similarityPercent(Set<String> a, Set<String> b) {
        if (a.isEmpty() || b.isEmpty()) {
            return 0;
        }
        int intersection = 0;
        for (String gram : a) {
            if (b.contains(gram)) {
                intersection++;
            }
        }
        int union = a.size() + b.size() - intersection;
        if (union == 0) {
            return 0;
        }
        return (int) Math.round(intersection * 100.0 / union);
    }
}
