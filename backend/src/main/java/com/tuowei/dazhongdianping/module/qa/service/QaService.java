package com.tuowei.dazhongdianping.module.qa.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.moderation.ModerationDecision;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.moderation.service.ContentModerationService;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
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
    private final AdminAuditMapper adminAuditMapper;

    public QaService(QaMapper mapper, ContentModerationService contentModerationService,
                     AdminAuditMapper adminAuditMapper) {
        this.mapper = mapper;
        this.contentModerationService = contentModerationService;
        this.adminAuditMapper = adminAuditMapper;
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
        ModerationDecision decision = contentModerationService.moderate(region, "qa", 0L, u.userId(), content);
        ShopQuestionRow row = new ShopQuestionRow();
        row.setRegion(region);
        row.setShopId(shopId);
        row.setUserId(u.userId());
        row.setContent(content.trim());
        row.setStatus(decision == ModerationDecision.REVIEW ? 0 : 1);
        mapper.insertQuestion(row);
        if (row.getStatus() == 0) {
            createAuditTask(12, row.getId(), region, decision.code());
        }
        return questionMap(mapper.selectQuestionForOwner(row.getId(), shopId, region, u.userId()));
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
        ModerationDecision decision = contentModerationService.moderate(region, "qa_answer", 0L, u.userId(), content);
        ShopAnswerRow row = new ShopAnswerRow();
        row.setRegion(region);
        row.setQuestionId(questionId);
        row.setUserId(u.userId());
        row.setContent(content.trim());
        row.setStatus(decision == ModerationDecision.REVIEW ? 0 : 1);
        mapper.insertAnswer(row);
        if (row.getStatus() == 1) {
            mapper.incrementAnswerCount(questionId);
        } else {
            createAuditTask(13, row.getId(), region, decision.code());
        }
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
        m.put("status", q.getStatus() == null ? 1 : q.getStatus());
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
        m.put("status", a.getStatus() == null ? 1 : a.getStatus());
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

    private void createAuditTask(int bizType, Long bizId, String region, int machineResult) {
        AuditTaskRow task = new AuditTaskRow();
        task.setBizType(bizType);
        task.setBizId(bizId);
        task.setRegion(region);
        task.setMachineResult(machineResult);
        task.setStatus(0);
        task.setAuditorId(0L);
        task.setRemark("机审待复核");
        adminAuditMapper.insertAuditTask(task);
    }
}
