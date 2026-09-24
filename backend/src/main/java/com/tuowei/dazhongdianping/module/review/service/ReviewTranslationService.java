package com.tuowei.dazhongdianping.module.review.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.review.mapper.ReviewMapper;
import com.tuowei.dazhongdianping.module.review.mapper.ReviewTranslationMapper;
import com.tuowei.dazhongdianping.module.review.model.ReviewTranslationRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ReviewTranslationService {

    private static final Set<String> LANGS = Set.of("zh", "en");

    private final ReviewMapper reviewMapper;
    private final ReviewTranslationMapper translationMapper;

    public ReviewTranslationService(ReviewMapper reviewMapper, ReviewTranslationMapper translationMapper) {
        this.reviewMapper = reviewMapper;
        this.translationMapper = translationMapper;
    }

    public List<Map<String, Object>> list(Long reviewId, String lang) {
        requirePublicReview(reviewId);
        String targetLang = normalizeOptionalLang(lang);
        return translationMapper.selectByReview(reviewId, region(), targetLang)
                .stream()
                .map(this::toMap)
                .toList();
    }

    @Transactional
    public Map<String, Object> save(Long reviewId, String targetLang, String content) {
        UserSession user = requireUser();
        requirePublicReview(reviewId);
        String lang = requireLang(targetLang);
        String text = content.trim();
        ReviewTranslationRow existing = translationMapper.selectByUser(reviewId, user.userId(), lang);
        if (existing == null) {
            ReviewTranslationRow row = new ReviewTranslationRow();
            row.setReviewId(reviewId);
            row.setRegion(region());
            row.setUserId(user.userId());
            row.setTargetLang(lang);
            row.setContent(text);
            translationMapper.insert(row);
            return toMap(translationMapper.selectById(row.getId()));
        }
        translationMapper.updateContent(existing.getId(), text);
        return toMap(translationMapper.selectById(existing.getId()));
    }

    private void requirePublicReview(Long reviewId) {
        if (reviewMapper.selectPublicReviewById(reviewId, region()) == null) {
            throw new NotFoundException("点评不存在");
        }
    }

    private String requireLang(String targetLang) {
        String lang = targetLang == null ? "" : targetLang.trim().toLowerCase(Locale.ROOT);
        if (!LANGS.contains(lang)) {
            throw new IllegalArgumentException("targetLang 仅支持 zh 或 en");
        }
        return lang;
    }

    private String normalizeOptionalLang(String lang) {
        if (lang == null || lang.isBlank()) {
            return null;
        }
        return lang.trim().toLowerCase(Locale.ROOT);
    }

    private Map<String, Object> toMap(ReviewTranslationRow row) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("reviewId", row.getReviewId());
        map.put("userId", row.getUserId());
        map.put("targetLang", row.getTargetLang());
        map.put("content", row.getContent());
        map.put("createdAt", row.getCreatedAt());
        map.put("updatedAt", row.getUpdatedAt());
        return map;
    }

    private UserSession requireUser() {
        UserSession user = UserSessionContext.get();
        if (user == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return user;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
