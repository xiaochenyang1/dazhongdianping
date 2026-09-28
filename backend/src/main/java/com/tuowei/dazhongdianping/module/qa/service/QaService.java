package com.tuowei.dazhongdianping.module.qa.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.moderation.service.ContentModerationService;
import com.tuowei.dazhongdianping.module.qa.mapper.QaMapper;
import com.tuowei.dazhongdianping.module.qa.model.ShopAnswerRow;
import com.tuowei.dazhongdianping.module.qa.model.ShopQuestionRow;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** "问大家"：门店问答的提问、回答与浏览。 */
@Service
public class QaService {

    private final QaMapper mapper;
    private final ContentModerationService contentModerationService;

    public QaService(QaMapper mapper, ContentModerationService contentModerationService) {
        this.mapper = mapper;
        this.contentModerationService = contentModerationService;
    }

    public PageResult<Map<String, Object>> questions(Long shopId, Integer page, Integer pageSize) {
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 10 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countQuestions(shopId, region);
        List<Map<String, Object>> list = mapper.selectQuestions(shopId, region, s, (p - 1) * s)
                .stream().map(this::questionMap).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional(noRollbackFor = IllegalArgumentException.class)
    public Map<String, Object> ask(Long shopId, String content) {
        UserSession u = requireUser();
        String region = region();
        if (!mapper.existsShop(shopId, region)) {
            throw new NotFoundException("门店不存在");
        }
        contentModerationService.moderate(region, "qa", 0L, u.userId(), content);
        ShopQuestionRow row = new ShopQuestionRow();
        row.setRegion(region);
        row.setShopId(shopId);
        row.setUserId(u.userId());
        row.setContent(content.trim());
        mapper.insertQuestion(row);
        return questionMap(mapper.selectQuestion(row.getId(), shopId, region));
    }

    public List<Map<String, Object>> answers(Long shopId, Long questionId) {
        ShopQuestionRow q = mapper.selectQuestion(questionId, shopId, region());
        if (q == null) {
            throw new NotFoundException("问题不存在");
        }
        return mapper.selectAnswers(questionId).stream().map(this::answerMap).toList();
    }

    @Transactional
    public Map<String, Object> answer(Long shopId, Long questionId, String content) {
        UserSession u = requireUser();
        String region = region();
        ShopQuestionRow q = mapper.selectQuestion(questionId, shopId, region);
        if (q == null) {
            throw new NotFoundException("问题不存在");
        }
        ShopAnswerRow row = new ShopAnswerRow();
        row.setRegion(region);
        row.setQuestionId(questionId);
        row.setUserId(u.userId());
        row.setContent(content.trim());
        mapper.insertAnswer(row);
        mapper.incrementAnswerCount(questionId);
        return answerMap(row);
    }

    private Map<String, Object> questionMap(ShopQuestionRow q) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", q.getId());
        m.put("shopId", q.getShopId());
        m.put("userId", q.getUserId());
        m.put("userNickname", q.getUserNickname() == null ? "" : q.getUserNickname());
        m.put("content", q.getContent());
        m.put("answerCount", q.getAnswerCount() == null ? 0 : q.getAnswerCount());
        m.put("latestAnswer", q.getLatestAnswer() == null ? "" : q.getLatestAnswer());
        m.put("createdAt", q.getCreatedAt());
        return m;
    }

    private Map<String, Object> answerMap(ShopAnswerRow a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", a.getId());
        m.put("questionId", a.getQuestionId());
        m.put("userId", a.getUserId());
        m.put("userNickname", a.getUserNickname() == null ? "" : a.getUserNickname());
        m.put("content", a.getContent());
        m.put("createdAt", a.getCreatedAt());
        return m;
    }

    private UserSession requireUser() {
        UserSession u = UserSessionContext.get();
        if (u == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return u;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
