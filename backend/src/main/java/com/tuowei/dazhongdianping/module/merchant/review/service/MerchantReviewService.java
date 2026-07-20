package com.tuowei.dazhongdianping.module.merchant.review.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.merchant.review.mapper.MerchantReviewMapper;
import com.tuowei.dazhongdianping.module.merchant.review.model.MerchantReviewAppealRow;
import com.tuowei.dazhongdianping.module.merchant.review.model.MerchantReviewRow;
import com.tuowei.dazhongdianping.module.merchant.review.model.ReviewMerchantReplyRow;
import com.tuowei.dazhongdianping.module.merchant.review.model.request.MerchantReviewAppealSaveRequest;
import com.tuowei.dazhongdianping.module.merchant.review.model.request.MerchantReviewReplyRequest;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MerchantReviewService {

    private static final int REVIEW_APPEAL_BIZ_TYPE = 6;
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final TypeReference<List<String>> STRING_LIST_TYPE = new TypeReference<>() {
    };

    private final MerchantReviewMapper mapper;
    private final MerchantAuthorizationService authorizationService;
    private final AdminAuditMapper adminAuditMapper;
    private final ObjectMapper objectMapper;

    public MerchantReviewService(MerchantReviewMapper mapper,
                                 MerchantAuthorizationService authorizationService,
                                 AdminAuditMapper adminAuditMapper,
                                 ObjectMapper objectMapper) {
        this.mapper = mapper;
        this.authorizationService = authorizationService;
        this.adminAuditMapper = adminAuditMapper;
        this.objectMapper = objectMapper;
    }

    public PageResult<Map<String, Object>> reviews(Long shopId,
                                                    Integer replyStatus,
                                                    Integer appealStatus,
                                                    Integer score,
                                                    String keyword,
                                                    LocalDate dateFrom,
                                                    LocalDate dateTo,
                                                    Integer page,
                                                    Integer pageSize) {
        MerchantSession session = merchant();
        authorizationService.requirePermission(session, "shop:view");
        if (shopId != null) {
            authorizationService.requireShop(session, "shop:view", shopId);
        }
        validateDateRange(dateFrom, dateTo);
        validateStatus(replyStatus, "replyStatus");
        validateAppealStatus(appealStatus);
        if (score != null && (score < 1 || score > 5)) {
            throw new IllegalArgumentException("评分筛选必须在 1 到 5 之间");
        }
        int normalizedPage = page == null ? 1 : Math.max(1, page);
        int normalizedPageSize = pageSize == null ? 20 : Math.min(100, Math.max(1, pageSize));
        List<Long> scopedShopIds = shopId == null ? authorizationService.scopedShopIds(session) : null;
        if (scopedShopIds != null && scopedShopIds.isEmpty()) {
            return new PageResult<>(List.of(), 0, normalizedPage, normalizedPageSize, false);
        }
        String normalizedKeyword = keyword == null || keyword.isBlank() ? null : keyword.trim();
        LocalDate dateToExclusive = dateTo == null ? null : dateTo.plusDays(1);
        long total = mapper.countReviews(
                session.merchantId(), region(), shopId, scopedShopIds, replyStatus, appealStatus, score,
                normalizedKeyword, dateFrom, dateToExclusive
        );
        List<Map<String, Object>> items = mapper.selectReviews(
                session.merchantId(), region(), shopId, scopedShopIds, replyStatus, appealStatus, score,
                normalizedKeyword, dateFrom, dateToExclusive,
                normalizedPageSize, (normalizedPage - 1) * normalizedPageSize
        ).stream().map(this::reviewMap).toList();
        return new PageResult<>(
                items,
                total,
                normalizedPage,
                normalizedPageSize,
                (long) normalizedPage * normalizedPageSize < total
        );
    }

    @Transactional
    public Map<String, Object> saveReply(Long reviewId, MerchantReviewReplyRequest request) {
        MerchantSession session = merchant();
        MerchantReviewRow review = requirePublicReviewInScope(session, reviewId, "review:reply");
        String content = request.content().trim();
        ReviewMerchantReplyRow existing = mapper.selectReply(reviewId);
        if (existing == null) {
            ReviewMerchantReplyRow row = new ReviewMerchantReplyRow();
            row.setReviewId(reviewId);
            row.setShopId(review.getShopId());
            row.setMerchantId(session.merchantId());
            row.setOperatorId(session.operatorId());
            row.setContent(content);
            mapper.insertReply(row);
            mapper.insertOperationLog(
                    session.merchantId(), session.operatorId(), "review_reply_create", "review", reviewId, content
            );
        } else {
            if (mapper.updateReply(reviewId, session.merchantId(), session.operatorId(), content) != 1) {
                throw new IllegalArgumentException("商家回复状态已变化，请刷新后重试");
            }
            mapper.insertOperationLog(
                    session.merchantId(), session.operatorId(), "review_reply_update", "review", reviewId, content
            );
        }
        return replyMap(mapper.selectReply(reviewId));
    }

    @Transactional
    public Map<String, Object> createAppealDraft(Long reviewId) {
        MerchantSession session = merchant();
        MerchantReviewRow review = requirePublicReviewInScope(session, reviewId, "review:appeal");
        MerchantReviewAppealRow existing = mapper.selectAppealByReview(session.merchantId(), region(), reviewId);
        if (existing != null) {
            return appealMap(existing);
        }
        MerchantReviewAppealRow row = new MerchantReviewAppealRow();
        row.setMerchantId(session.merchantId());
        row.setOperatorId(session.operatorId());
        row.setReviewId(reviewId);
        row.setShopId(review.getShopId());
        row.setRegion(region());
        row.setReason("");
        row.setEvidenceUrls("[]");
        row.setStatus(0);
        mapper.insertAppeal(row);
        mapper.insertOperationLog(
                session.merchantId(), session.operatorId(), "review_appeal_draft_create", "review", reviewId, ""
        );
        return appealMap(requireAppeal(session, row.getId()));
    }

    @Transactional
    public Map<String, Object> saveAppeal(Long appealId, MerchantReviewAppealSaveRequest request) {
        MerchantSession session = merchant();
        MerchantReviewAppealRow row = requireAppeal(session, appealId);
        authorizationService.requireShop(session, "review:appeal", row.getShopId());
        if (row.getStatus() == 3) {
            mapper.resetRejectedAppeal(appealId, session.merchantId(), session.operatorId());
            row = requireAppeal(session, appealId);
        }
        if (row.getStatus() != 0) {
            throw new IllegalArgumentException("申诉当前状态不允许编辑");
        }
        String reason = request.reason().trim();
        String evidenceUrls = toJson(normalizeEvidenceUrls(request.evidenceUrls()));
        if (mapper.updateAppealDraft(appealId, session.merchantId(), session.operatorId(), reason, evidenceUrls) != 1) {
            throw new IllegalArgumentException("申诉状态已变化，请刷新后重试");
        }
        mapper.insertOperationLog(
                session.merchantId(), session.operatorId(), "review_appeal_save", "review", row.getReviewId(), reason
        );
        return appealMap(requireAppeal(session, appealId));
    }

    @Transactional
    public Map<String, Object> submitAppeal(Long appealId) {
        MerchantSession session = merchant();
        MerchantReviewAppealRow row = requireAppeal(session, appealId);
        authorizationService.requireShop(session, "review:appeal", row.getShopId());
        if (row.getStatus() != 0) {
            throw new IllegalArgumentException("申诉当前状态不允许提交");
        }
        validateAppeal(row);
        MerchantReviewRow review = requirePublicReviewInScope(session, row.getReviewId(), "review:appeal");
        if (mapper.submitAppeal(appealId, session.merchantId(), session.operatorId(), review.getUpdatedAt()) != 1) {
            throw new IllegalArgumentException("申诉状态已变化，请刷新后重试");
        }
        AuditTaskRow task = new AuditTaskRow();
        task.setBizType(REVIEW_APPEAL_BIZ_TYPE);
        task.setBizId(appealId);
        task.setRegion(region());
        task.setMachineResult(0);
        task.setStatus(0);
        task.setAuditorId(0L);
        task.setRemark("");
        adminAuditMapper.insertAuditTask(task);
        mapper.insertOperationLog(
                session.merchantId(), session.operatorId(), "review_appeal_submit", "review", row.getReviewId(), row.getReason()
        );
        return appealMap(requireAppeal(session, appealId));
    }

    public MerchantReviewAppealRow pendingAppealForAudit(Long appealId, String auditRegion) {
        return mapper.selectPendingAppealForAudit(appealId, auditRegion);
    }

    public Long passAppeal(MerchantReviewAppealRow appeal, Long auditBy, String remark) {
        MerchantReviewRow review = mapper.selectPublicReviewInMerchantScope(
                appeal.getReviewId(), appeal.getMerchantId(), appeal.getRegion());
        if (review == null) {
            throw new NotFoundException("点评不存在或已不公开");
        }
        if (!Objects.equals(review.getUpdatedAt(), appeal.getBaseReviewUpdatedAt())) {
            throw new IllegalArgumentException("点评内容已变化，请驳回后让商户重新提交");
        }
        String auditRemark = remark == null || remark.isBlank()
                ? "商户申诉通过"
                : "商户申诉通过：" + remark.trim();
        if (mapper.hideReviewForAppeal(
                appeal.getReviewId(), appeal.getRegion(), appeal.getBaseReviewUpdatedAt(), auditRemark
        ) != 1) {
            throw new IllegalArgumentException("点评状态已变化，请刷新后重试");
        }
        if (mapper.approveAppeal(appeal.getId(), appeal.getRegion(), auditBy) != 1) {
            throw new IllegalArgumentException("申诉状态已变化，请刷新后重试");
        }
        mapper.insertOperationLog(
                appeal.getMerchantId(), appeal.getOperatorId(), "review_appeal_pass",
                "review", appeal.getReviewId(), auditRemark
        );
        return appeal.getShopId();
    }

    public void rejectAppeal(MerchantReviewAppealRow appeal, Long auditBy, String reason) {
        if (mapper.rejectAppeal(appeal.getId(), appeal.getRegion(), auditBy, reason) != 1) {
            throw new IllegalArgumentException("申诉状态已变化，请刷新后重试");
        }
        mapper.insertOperationLog(
                appeal.getMerchantId(), appeal.getOperatorId(), "review_appeal_reject",
                "review", appeal.getReviewId(), reason
        );
    }

    private MerchantReviewRow requirePublicReviewInScope(MerchantSession session, Long reviewId, String permission) {
        authorizationService.requirePermission(session, permission);
        MerchantReviewRow row = mapper.selectPublicReviewInMerchantScope(reviewId, session.merchantId(), region());
        if (row == null) {
            throw new NotFoundException("点评不存在");
        }
        authorizationService.requireShop(session, permission, row.getShopId());
        return row;
    }

    private MerchantReviewAppealRow requireAppeal(MerchantSession session, Long appealId) {
        MerchantReviewAppealRow row = mapper.selectAppeal(session.merchantId(), region(), appealId);
        if (row == null) {
            throw new NotFoundException("申诉不存在");
        }
        return row;
    }

    private Map<String, Object> reviewMap(MerchantReviewRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("shopId", row.getShopId());
        result.put("shopName", row.getShopName());
        result.put("userId", row.getUserId());
        result.put("userName", row.getUserName());
        result.put("content", row.getContent());
        result.put("scoreOverall", row.getScoreOverall());
        result.put("scoreTaste", row.getScoreTaste());
        result.put("scoreEnv", row.getScoreEnv());
        result.put("scoreService", row.getScoreService());
        result.put("cost", row.getCost());
        result.put("currency", row.getCurrency());
        result.put("likeCount", row.getLikeCount());
        result.put("commentCount", row.getCommentCount());
        result.put("auditStatus", row.getAuditStatus());
        result.put("status", row.getStatus());
        result.put("tags", splitTags(row.getTags()));
        result.put("createdAt", format(row.getCreatedAt()));
        result.put("updatedAt", format(row.getUpdatedAt()));
        result.put("merchantReply", replyMapFromReview(row));
        result.put("appeal", appealSummary(row));
        return result;
    }

    private Map<String, Object> replyMap(ReviewMerchantReplyRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("reviewId", row.getReviewId());
        result.put("shopId", row.getShopId());
        result.put("merchantId", row.getMerchantId());
        result.put("merchantName", row.getMerchantName());
        result.put("operatorId", row.getOperatorId());
        result.put("content", row.getContent());
        result.put("repliedAt", format(row.getCreatedAt()));
        result.put("updatedAt", format(row.getUpdatedAt()));
        return result;
    }

    private Map<String, Object> replyMapFromReview(MerchantReviewRow row) {
        if (row.getReplyId() == null) {
            return null;
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getReplyId());
        result.put("merchantName", row.getMerchantName());
        result.put("operatorId", row.getReplyOperatorId());
        result.put("content", row.getReplyContent());
        result.put("repliedAt", format(row.getReplyCreatedAt()));
        result.put("updatedAt", format(row.getReplyUpdatedAt()));
        return result;
    }

    private Map<String, Object> appealSummary(MerchantReviewRow row) {
        if (row.getAppealId() == null) {
            return null;
        }
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getAppealId());
        result.put("status", row.getAppealStatus());
        result.put("statusText", appealStatusText(row.getAppealStatus()));
        return result;
    }

    private Map<String, Object> appealMap(MerchantReviewAppealRow row) {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", row.getId());
        result.put("merchantId", row.getMerchantId());
        result.put("operatorId", row.getOperatorId());
        result.put("reviewId", row.getReviewId());
        result.put("shopId", row.getShopId());
        result.put("region", row.getRegion());
        result.put("reason", row.getReason());
        result.put("evidenceUrls", parseEvidenceUrls(row.getEvidenceUrls()));
        result.put("status", row.getStatus());
        result.put("statusText", appealStatusText(row.getStatus()));
        result.put("rejectReason", row.getRejectReason());
        result.put("submittedAt", format(row.getSubmittedAt()));
        result.put("auditedAt", format(row.getAuditedAt()));
        result.put("createdAt", format(row.getCreatedAt()));
        result.put("updatedAt", format(row.getUpdatedAt()));
        return result;
    }

    private void validateDateRange(LocalDate dateFrom, LocalDate dateTo) {
        if (dateFrom != null && dateTo != null && dateFrom.isAfter(dateTo)) {
            throw new IllegalArgumentException("dateFrom 不能晚于 dateTo");
        }
        if (dateFrom != null && dateTo != null && ChronoUnit.DAYS.between(dateFrom, dateTo) >= 90) {
            throw new IllegalArgumentException("点评查询范围不能超过 90 天");
        }
    }

    private void validateStatus(Integer status, String name) {
        if (status != null && status != 0 && status != 1) {
            throw new IllegalArgumentException(name + " 只允许 0 或 1");
        }
    }

    private void validateAppealStatus(Integer status) {
        if (status != null && (status < 0 || status > 4)) {
            throw new IllegalArgumentException("appealStatus 只允许 0 到 4");
        }
    }

    private void validateAppeal(MerchantReviewAppealRow row) {
        String reason = row.getReason() == null ? "" : row.getReason().trim();
        if (reason.length() < 10 || reason.length() > 500) {
            throw new IllegalArgumentException("申诉理由长度必须为 10 到 500 字");
        }
        normalizeEvidenceUrls(parseEvidenceUrls(row.getEvidenceUrls()));
    }

    private String toJson(List<String> values) {
        try {
            return objectMapper.writeValueAsString(values);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("证据 URL 格式非法");
        }
    }

    private List<String> parseEvidenceUrls(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(value, STRING_LIST_TYPE);
        } catch (JsonProcessingException ex) {
            throw new IllegalArgumentException("证据 URL 格式非法");
        }
    }

    private List<String> normalizeEvidenceUrls(List<String> values) {
        if (values == null) {
            return List.of();
        }
        List<String> normalized = values.stream()
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .toList();
        if (normalized.size() > 6) {
            throw new IllegalArgumentException("证据 URL 最多 6 个");
        }
        return normalized;
    }

    private List<String> splitTags(String tags) {
        if (tags == null || tags.isBlank()) {
            return List.of();
        }
        return List.of(tags.split(",")).stream().map(String::trim)
                .filter(value -> !value.isBlank()).toList();
    }

    private String appealStatusText(Integer status) {
        return switch (status == null ? 0 : status) {
            case 1 -> "待审核";
            case 2 -> "已通过";
            case 3 -> "已驳回";
            case 4 -> "已失效";
            default -> "草稿";
        };
    }

    private String format(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private MerchantSession merchant() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
