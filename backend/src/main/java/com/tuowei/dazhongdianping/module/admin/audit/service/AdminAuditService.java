package com.tuowei.dazhongdianping.module.admin.audit.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditLogQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditSlaAlertQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditSlaAlertRow;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueMetricRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueOverdueRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueSlaThreshold;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditLogRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditTaskQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.ModeratedContentRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditPassRequest;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditRejectRequest;
import com.tuowei.dazhongdianping.module.admin.audit.model.response.AdminAuditLogResponse;
import com.tuowei.dazhongdianping.module.admin.audit.model.response.AdminAuditQueueMetricResponse;
import com.tuowei.dazhongdianping.module.admin.audit.model.response.AdminAuditSlaAlertResponse;
import com.tuowei.dazhongdianping.module.admin.audit.model.response.AdminAuditTaskResponse;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminPermissionChecker;
import com.tuowei.dazhongdianping.module.admin.user.mapper.AdminAppUserMapper;
import com.tuowei.dazhongdianping.module.admin.user.service.AdminAppUserService;
import com.tuowei.dazhongdianping.module.auth.appeal.model.UserBanAppealRow;
import com.tuowei.dazhongdianping.module.auth.appeal.service.UserBanAppealService;
import com.tuowei.dazhongdianping.module.auth.certification.model.UserExpertCertificationRow;
import com.tuowei.dazhongdianping.module.auth.certification.service.UserExpertCertificationService;
import com.tuowei.dazhongdianping.module.merchant.verification.model.MerchantVerificationRow;
import com.tuowei.dazhongdianping.module.merchant.verification.service.MerchantVerificationService;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.review.mapper.ReviewMapper;
import com.tuowei.dazhongdianping.module.review.service.ReviewService;
import com.tuowei.dazhongdianping.module.message.mapper.MessageMapper;
import com.tuowei.dazhongdianping.module.message.model.MessageRow;
import com.tuowei.dazhongdianping.module.message.model.response.MessageResponse;
import com.tuowei.dazhongdianping.module.notification.websocket.NotificationSessionRegistry;
import com.tuowei.dazhongdianping.module.qa.mapper.QaMapper;
import com.tuowei.dazhongdianping.module.qa.model.ShopQuestionRow;
import com.tuowei.dazhongdianping.module.circle.mapper.CircleMapper;
import com.tuowei.dazhongdianping.module.community.mapper.CommunityMapper;
import com.tuowei.dazhongdianping.module.community.model.PostRow;
import com.tuowei.dazhongdianping.module.notification.service.MentionNotificationService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.notification.service.TopicUpdateNotificationService;
import com.tuowei.dazhongdianping.module.topic.service.TopicService;
import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangeRow;
import com.tuowei.dazhongdianping.module.merchant.shop.service.MerchantShopChangeService;
import com.tuowei.dazhongdianping.module.merchant.trade.service.MerchantTradeService;
import com.tuowei.dazhongdianping.module.merchant.review.model.MerchantReviewAppealRow;
import com.tuowei.dazhongdianping.module.merchant.review.service.MerchantReviewService;
import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.util.StringUtils;

@Service
public class AdminAuditService {

    private static final int REVIEW_BIZ_TYPE = 3;
    private static final int POST_BIZ_TYPE = 4;
    private static final int DEAL_BIZ_TYPE = 2;
    private static final int SHOP_CHANGE_BIZ_TYPE = 5;
    private static final int REVIEW_APPEAL_BIZ_TYPE = 6;
    private static final int EXPERT_CERTIFICATION_BIZ_TYPE = 7;
    private static final int USER_APPEAL_BIZ_TYPE = 8;
    private static final int MERCHANT_VERIFICATION_BIZ_TYPE = 9;
    private static final int REVIEW_COMMENT_BIZ_TYPE = 10;
    private static final int POST_COMMENT_BIZ_TYPE = 11;
    private static final int QA_QUESTION_BIZ_TYPE = 12;
    private static final int QA_ANSWER_BIZ_TYPE = 13;
    private static final int MESSAGE_BIZ_TYPE = 14;
    private static final int AUDIT_CLAIM_LEASE_MINUTES = 15;
    private static final List<Integer> MODERATED_BIZ_TYPES = List.of(
            REVIEW_COMMENT_BIZ_TYPE, POST_COMMENT_BIZ_TYPE, QA_QUESTION_BIZ_TYPE, QA_ANSWER_BIZ_TYPE, MESSAGE_BIZ_TYPE
    );
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final String REVIEW_AUDIT_RESULT_TYPE = "review.audit.result";
    private static final String EXPERT_CERT_RESULT_TYPE = "expert.certification.result";
    private static final String POST_AUDIT_RESULT_TYPE = "post.audit.result";
    private static final String REVIEW_HIDDEN_TYPE = "review.hidden";

    private final AdminAuditMapper adminAuditMapper;
    private final ReviewMapper reviewMapper;
    private final ReviewService reviewService;
    private final MerchantShopChangeService merchantShopChangeService;
    private final MerchantTradeService merchantTradeService;
    private final MerchantReviewService merchantReviewService;
    private final UserExpertCertificationService userExpertCertificationService;
    private final MerchantVerificationService merchantVerificationService;
    private final UserBanAppealService userBanAppealService;
    private final AdminAppUserMapper adminAppUserMapper;
    private final ApplicationEventPublisher applicationEventPublisher;
    private final CircleMapper circleMapper;
    private final CommunityMapper communityMapper;
    private final TopicService topicService;
    private final MentionNotificationService mentionNotificationService;
    private final TopicUpdateNotificationService topicUpdateNotificationService;
    private final NotificationService notificationService;
    private final AdminPermissionChecker permissionChecker;
    private final MessageMapper messageMapper;
    private final QaMapper qaMapper;
    private final NotificationSessionRegistry notificationSessions;

    @Value("${app.admin.audit.sla.review-comment-minutes:30}")
    private int reviewCommentSlaMinutes = 30;

    @Value("${app.admin.audit.sla.post-comment-minutes:30}")
    private int postCommentSlaMinutes = 30;

    @Value("${app.admin.audit.sla.shop-question-minutes:60}")
    private int shopQuestionSlaMinutes = 60;

    @Value("${app.admin.audit.sla.shop-answer-minutes:60}")
    private int shopAnswerSlaMinutes = 60;

    @Value("${app.admin.audit.sla.direct-message-minutes:15}")
    private int directMessageSlaMinutes = 15;

    public AdminAuditService(AdminAuditMapper adminAuditMapper,
                             ReviewMapper reviewMapper,
                             ReviewService reviewService,
                             MerchantShopChangeService merchantShopChangeService,
                             MerchantTradeService merchantTradeService,
                             MerchantReviewService merchantReviewService,
                             UserExpertCertificationService userExpertCertificationService,
                             MerchantVerificationService merchantVerificationService,
                             UserBanAppealService userBanAppealService,
                             AdminAppUserMapper adminAppUserMapper,
                             ApplicationEventPublisher applicationEventPublisher,
                             CircleMapper circleMapper,
                             CommunityMapper communityMapper,
                             TopicService topicService,
                             MentionNotificationService mentionNotificationService,
                             TopicUpdateNotificationService topicUpdateNotificationService,
                             NotificationService notificationService,
                             AdminPermissionChecker permissionChecker,
                             MessageMapper messageMapper,
                             QaMapper qaMapper,
                             NotificationSessionRegistry notificationSessions) {
        this.adminAuditMapper = adminAuditMapper;
        this.reviewMapper = reviewMapper;
        this.reviewService = reviewService;
        this.merchantShopChangeService = merchantShopChangeService;
        this.merchantTradeService = merchantTradeService;
        this.merchantReviewService = merchantReviewService;
        this.userExpertCertificationService = userExpertCertificationService;
        this.merchantVerificationService = merchantVerificationService;
        this.userBanAppealService = userBanAppealService;
        this.adminAppUserMapper = adminAppUserMapper;
        this.applicationEventPublisher = applicationEventPublisher;
        this.circleMapper = circleMapper;
        this.communityMapper = communityMapper;
        this.topicService = topicService;
        this.mentionNotificationService = mentionNotificationService;
        this.topicUpdateNotificationService = topicUpdateNotificationService;
        this.notificationService = notificationService;
        this.permissionChecker = permissionChecker;
        this.messageMapper = messageMapper;
        this.qaMapper = qaMapper;
        this.notificationSessions = notificationSessions;
    }

    public PageResult<AdminAuditLogResponse> listLogs(AdminAuditLogQuery query) {
        query.normalize();
        long total = adminAuditMapper.countAuditLogs(query);
        List<AdminAuditLogResponse> items = adminAuditMapper.selectAuditLogs(query).stream()
                .map(this::toAuditLogResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    public PageResult<AdminAuditTaskResponse> listTasks(AdminAuditTaskQuery query) {
        query.normalize();
        query.setRegion(currentRegion().name());
        query.setAllowedBizTypes(allowedBizTypes(false));
        if (query.isOverdueOnly()) {
            if ((query.getStatus() != null && query.getStatus() != 0)
                    || (query.getBizType() != null && !isModeratedBizType(query.getBizType()))) {
                throw new IllegalArgumentException("超时筛选仅适用于待复审内容");
            }
            query.setStatus(0);
            query.setAllowedBizTypes(query.getAllowedBizTypes().stream()
                    .filter(MODERATED_BIZ_TYPES::contains)
                    .toList());
        }
        query.setSlaThresholds(query.getStatus() != null && query.getStatus() == 0
                ? slaThresholds(MODERATED_BIZ_TYPES.stream()
                        .filter(query.getAllowedBizTypes()::contains)
                        .toList())
                : List.of());
        if (query.getAssignmentFilter() != null) {
            if (!isModeratedBizType(query.getBizType())
                    && !(query.getBizType() == null && query.isOverdueOnly())) {
                throw new IllegalArgumentException("负责人筛选仅适用于内容复审队列");
            }
            query.setCurrentAdminId(currentAdmin().adminId());
        }
        long total = adminAuditMapper.countAuditTasks(query);
        List<AdminAuditTaskResponse> items = adminAuditMapper.selectAuditTasks(query).stream()
                .map(this::toAuditTaskResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    @Transactional
    public AdminAuditTaskResponse claimTask(Long taskId, String requestIp) {
        AuditTaskRow task = requireModeratedPendingTask(taskId);
        Long adminId = currentAdmin().adminId();
        if (adminAuditMapper.claimPendingModeratedAuditTask(taskId, adminId, AUDIT_CLAIM_LEASE_MINUTES) == 0) {
            AuditTaskRow current = adminAuditMapper.selectAuditTaskById(taskId);
            if (current != null && current.getStatus() != null && current.getStatus() == 0
                    && current.getClaimedByAdminId() != null
                    && !current.getClaimedByAdminId().equals(adminId)) {
                throw new ConflictException("任务正由" + safeText(current.getClaimedByAdminName()) + "认领");
            }
            throw new ConflictException("审核任务状态已变更，刷新后重试");
        }
        adminAuditMapper.insertAuditLog(adminId, "audit_automod_claim", "audit_task:" + taskId,
                "认领内容复审任务，有效期 " + AUDIT_CLAIM_LEASE_MINUTES + " 分钟", normalizeIp(requestIp));
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    @Transactional
    public AdminAuditTaskResponse releaseTask(Long taskId, String requestIp) {
        AuditTaskRow task = requireModeratedPendingTask(taskId);
        Long adminId = currentAdmin().adminId();
        if (adminAuditMapper.releasePendingModeratedAuditTask(taskId, adminId) == 0) {
            throw new ConflictException("该任务当前不属于你的认领");
        }
        adminAuditMapper.insertAuditLog(adminId, "audit_automod_release", "audit_task:" + taskId,
                "释放内容复审任务", normalizeIp(requestIp));
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    public List<AdminAuditQueueMetricResponse> listModerationQueueMetrics() {
        List<Integer> readableTypes = MODERATED_BIZ_TYPES.stream()
                .filter(allowedBizTypes(false)::contains)
                .toList();
        if (readableTypes.isEmpty()) {
            return List.of();
        }
        Map<Integer, AuditQueueMetricRow> metricsByType = adminAuditMapper
                .selectModerationQueueMetrics(currentRegion().name(), readableTypes)
                .stream()
                .collect(Collectors.toMap(AuditQueueMetricRow::getBizType, row -> row));
        Map<Integer, Long> overdueCountsByType = adminAuditMapper
                .selectModerationQueueOverdueCounts(currentRegion().name(), readableTypes, slaThresholds(readableTypes))
                .stream()
                .collect(Collectors.toMap(AuditQueueOverdueRow::getBizType, row -> row.getOverdueCount() == null ? 0L : row.getOverdueCount()));
        return readableTypes.stream()
                .map(bizType -> {
                    AuditQueueMetricRow row = metricsByType.get(bizType);
                    return new AdminAuditQueueMetricResponse(
                            bizType,
                            bizTypeText(bizType),
                            row == null || row.getPendingCount() == null ? 0L : row.getPendingCount(),
                            row == null ? null : formatNullableDateTime(row.getOldestPendingAt()),
                            row == null ? null : row.getOldestPendingAgeSeconds(),
                            overdueCountsByType.getOrDefault(bizType, 0L),
                            slaMinutes(bizType),
                            row == null || row.getProcessedCount() == null ? 0L : row.getProcessedCount(),
                            row == null ? null : row.getAverageProcessingSeconds()
                    );
                })
                .toList();
    }

    public List<AuditQueueSlaThreshold> moderationSlaThresholds() {
        return slaThresholds(MODERATED_BIZ_TYPES);
    }

    public PageResult<AdminAuditSlaAlertResponse> listSlaAlerts(AdminAuditSlaAlertQuery query) {
        query.normalize();
        query.setRegion(currentRegion().name());
        query.setAllowedBizTypes(allowedBizTypes(false).stream().filter(MODERATED_BIZ_TYPES::contains).toList());
        if (query.getAllowedBizTypes().isEmpty()) {
            return new PageResult<>(List.of(), 0, query.getPage(), query.getPageSize(), false);
        }
        long total = adminAuditMapper.countAdminAuditSlaAlerts(query);
        List<AdminAuditSlaAlertResponse> items = adminAuditMapper.selectAdminAuditSlaAlerts(query).stream()
                .map(this::toSlaAlertResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    private List<AuditQueueSlaThreshold> slaThresholds(List<Integer> bizTypes) {
        return bizTypes.stream()
                .map(bizType -> new AuditQueueSlaThreshold(bizType, slaMinutes(bizType)))
                .toList();
    }

    private int slaMinutes(int bizType) {
        int minutes = switch (bizType) {
            case REVIEW_COMMENT_BIZ_TYPE -> reviewCommentSlaMinutes;
            case POST_COMMENT_BIZ_TYPE -> postCommentSlaMinutes;
            case QA_QUESTION_BIZ_TYPE -> shopQuestionSlaMinutes;
            case QA_ANSWER_BIZ_TYPE -> shopAnswerSlaMinutes;
            case MESSAGE_BIZ_TYPE -> directMessageSlaMinutes;
            default -> throw new IllegalArgumentException("不支持的人工复核类型: " + bizType);
        };
        return Math.max(1, minutes);
    }

    public Map<String, Object> shopChangeDetail(Long changeId) {
        requireAuditPermission(SHOP_CHANGE_BIZ_TYPE, false);
        return merchantShopChangeService.detailForAdmin(changeId, currentRegion().name());
    }

    public Map<String, Object> dealDetail(Long dealId) {
        requireAuditPermission(DEAL_BIZ_TYPE, false);
        return merchantTradeService.dealForAdmin(dealId, currentRegion().name());
    }

    @Transactional
    public AdminAuditTaskResponse passTask(Long taskId, AdminAuditPassRequest request, String requestIp) {
        AuditTaskRow task = requirePendingTask(taskId);
        requireAuditPermission(task.getBizType(), true);
        if (isModeratedBizType(task.getBizType())) {
            return decideModeratedTask(task, 1, normalizeRemark(request.getRemark()), "audit_automod_pass", requestIp);
        }
        if (task.getBizType() == DEAL_BIZ_TYPE) {
            return passDealTask(task, request, requestIp);
        }
        if (task.getBizType() == SHOP_CHANGE_BIZ_TYPE) {
            return passShopChangeTask(task, request, requestIp);
        }
        if (task.getBizType() == REVIEW_APPEAL_BIZ_TYPE) {
            return passReviewAppealTask(task, request, requestIp);
        }
        if (task.getBizType() == EXPERT_CERTIFICATION_BIZ_TYPE) {
            return passExpertCertificationTask(task, request, requestIp);
        }
        if (task.getBizType() == MERCHANT_VERIFICATION_BIZ_TYPE) {
            return passMerchantVerificationTask(task, request, requestIp);
        }
        if (task.getBizType() == USER_APPEAL_BIZ_TYPE) {
            return passUserAppealTask(task, request, requestIp);
        }
        if (task.getBizType() == POST_BIZ_TYPE) {
            return decidePostTask(task, 1, normalizeRemark(request.getRemark()), "audit_post_pass", requestIp);
        }
        ReviewRow review = reviewMapper.selectReviewById(task.getBizId());
        if (review == null) {
            throw new NotFoundException("点评不存在");
        }

        int affected = adminAuditMapper.updateAuditTaskDecision(taskId, 1, currentAdmin().adminId(), normalizeRemark(request.getRemark()));
        if (affected == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }

        if (reviewMapper.updateReviewAuditDecision(task.getBizId(), 1, "") == 0) {
            throw new NotFoundException("点评不存在");
        }
        reviewMapper.resolvePendingReviewReports(task.getBizId());
        reviewService.recalculateShopAggregate(review.getShopId());
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(review.getShopId()));
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_review_pass",
                "review:" + review.getId(),
                normalizeRemark(request.getRemark()),
                normalizeIp(requestIp)
        );
        notifyReviewAuditResult(review, true, normalizeRemark(request.getRemark()));

        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(taskId));
    }

    @Transactional
    public AdminAuditTaskResponse rejectTask(Long taskId, AdminAuditRejectRequest request, String requestIp) {
        AuditTaskRow task = requirePendingTask(taskId);
        requireAuditPermission(task.getBizType(), true);
        if (isModeratedBizType(task.getBizType())) {
            return decideModeratedTask(task, 2, request.getReason().trim(), "audit_automod_reject", requestIp);
        }
        if (task.getBizType() == DEAL_BIZ_TYPE) {
            return rejectDealTask(task, request, requestIp);
        }
        if (task.getBizType() == SHOP_CHANGE_BIZ_TYPE) {
            return rejectShopChangeTask(task, request, requestIp);
        }
        if (task.getBizType() == REVIEW_APPEAL_BIZ_TYPE) {
            return rejectReviewAppealTask(task, request, requestIp);
        }
        if (task.getBizType() == EXPERT_CERTIFICATION_BIZ_TYPE) {
            return rejectExpertCertificationTask(task, request, requestIp);
        }
        if (task.getBizType() == MERCHANT_VERIFICATION_BIZ_TYPE) {
            return rejectMerchantVerificationTask(task, request, requestIp);
        }
        if (task.getBizType() == USER_APPEAL_BIZ_TYPE) {
            return rejectUserAppealTask(task, request, requestIp);
        }
        if (task.getBizType() == POST_BIZ_TYPE) {
            return decidePostTask(task, 2, request.getReason().trim(), "audit_post_reject", requestIp);
        }
        ReviewRow review = reviewMapper.selectReviewById(task.getBizId());
        if (review == null) {
            throw new NotFoundException("点评不存在");
        }

        int affected = adminAuditMapper.updateAuditTaskDecision(taskId, 2, currentAdmin().adminId(), request.getReason().trim());
        if (affected == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }

        if (reviewMapper.updateReviewAuditDecision(task.getBizId(), 2, request.getReason().trim()) == 0) {
            throw new NotFoundException("点评不存在");
        }
        adminAuditMapper.invalidatePendingCommentAuditTasksByContent(
                REVIEW_COMMENT_BIZ_TYPE, task.getBizId(), "任务失效：点评未通过审核"
        );
        reviewService.invalidateMerchantAppealsForReview(task.getBizId(), "任务失效：点评已被平台隐藏");
        reviewMapper.resolvePendingReviewReports(task.getBizId());
        reviewService.recalculateShopAggregate(review.getShopId());
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(review.getShopId()));
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_review_reject",
                "review:" + review.getId(),
                request.getReason().trim(),
                normalizeIp(requestIp)
        );
        notifyReviewAuditResult(review, false, request.getReason().trim());

        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(taskId));
    }

    private AdminAuditTaskResponse decideModeratedTask(
            AuditTaskRow task,
            int status,
            String remark,
            String action,
            String requestIp
    ) {
        requireClaimOwner(task);
        ModeratedContentRow content = adminAuditMapper.selectModeratedContent(task.getBizType(), task.getBizId());
        if (content == null) {
            throw new NotFoundException("待审核内容不存在或已处理");
        }
        MessageRow message = task.getBizType() == MESSAGE_BIZ_TYPE
                ? messageMapper.selectPendingMessage(task.getBizId())
                : null;
        if (task.getBizType() == MESSAGE_BIZ_TYPE && message == null) {
            throw new NotFoundException("待审核私信不存在或已处理");
        }
        if (adminAuditMapper.updateClaimedModeratedAuditTaskDecision(
                task.getId(), status, currentAdmin().adminId(), remark) == 0) {
            throw new ConflictException("认领已失效或任务状态已变更，请重新认领后重试");
        }
        if (adminAuditMapper.updateModeratedContentStatus(task.getBizType(), task.getBizId(), status, remark) == 0) {
            throw new IllegalArgumentException("审核内容状态已变更");
        }

        if (task.getBizType() == REVIEW_COMMENT_BIZ_TYPE) {
            reviewMapper.updateReviewInteractionCounts(
                    content.getRelatedId(),
                    reviewMapper.countReviewLikes(content.getRelatedId()),
                    reviewMapper.countReviewComments(content.getRelatedId())
            );
            if (status == 1) {
                ReviewRow review = reviewMapper.selectReviewById(content.getRelatedId());
                if (review != null) {
                    notifyCommentTarget(review.getUserId(), content, review.getRegion(), "review.comment",
                            "点评新评论", "/reviews/" + review.getId());
                    if (!java.util.Objects.equals(review.getUserId(), content.getReplyToUserId())) {
                        notifyCommentTarget(content.getReplyToUserId(), content, review.getRegion(), "review.comment.reply",
                                "评论被回复", "/reviews/" + review.getId());
                    }
                    mentionNotificationService.notifyMentionedUsers(
                            content.getUserId(), review.getRegion(), content.getContent(), "有人@了你",
                            "有人在点评评论中提到了你", "/reviews/" + review.getId());
                }
            }
        } else if (task.getBizType() == POST_COMMENT_BIZ_TYPE) {
            communityMapper.refreshPostCommentCount(content.getRelatedId());
            if (status == 1) {
                PostRow post = communityMapper.selectPostById(content.getRelatedId(), currentRegion().name());
                if (post != null) {
                    topicService.touchTopicsByPostId(post.getId());
                    notifyCommentTarget(post.getUserId(), content, post.getRegion(), "post.comment",
                            "帖子新评论", "/community/posts/" + post.getId());
                    if (!java.util.Objects.equals(post.getUserId(), content.getReplyToUserId())) {
                        notifyCommentTarget(content.getReplyToUserId(), content, post.getRegion(), "post.comment.reply",
                                "评论被回复", "/community/posts/" + post.getId());
                    }
                    mentionNotificationService.notifyMentionedUsers(
                            content.getUserId(), post.getRegion(), content.getContent(), "有人@了你",
                            "有人在帖子评论中提到了你", "/community/posts/" + post.getId());
                }
            }
        } else if (task.getBizType() == QA_ANSWER_BIZ_TYPE && status == 1) {
            qaMapper.incrementAnswerCount(content.getRelatedId());
            ShopQuestionRow question = qaMapper.selectQuestionByIdForAudit(content.getRelatedId());
            if (question != null) {
                notifyCommentTarget(question.getUserId(), content, question.getRegion(), "qa.answer",
                        "问题有了新回答", "/shops/" + question.getShopId());
            }
        } else if (task.getBizType() == MESSAGE_BIZ_TYPE) {
            message.setStatus(status);
            if (status == 1) {
                if (messageMapper.updateConversation(message.getConversationId(), message.getId(), preview(message.getContent())) == 0) {
                    throw new NotFoundException("私信会话不存在");
                }
                notificationService.create(
                        message.getToUserId(), message.getFromUserId(), "GLOBAL", "message.direct", "收到私信",
                        messageMapper.selectUserName(message.getFromUserId()) + "：" + preview(message.getContent()),
                        "/messages/conversations/" + message.getConversationId()
                );
                notifyMessageReceiver(message);
            } else {
                notificationService.create(
                        message.getFromUserId(), "GLOBAL", "automod.audit.result", "私信未通过审核",
                        "你的私信未通过审核" + (StringUtils.hasText(remark) ? "：" + remark : ""),
                        "/messages/conversations/" + message.getConversationId()
                );
            }
        }

        if (task.getBizType() != MESSAGE_BIZ_TYPE) {
            notifyModeratedContentAuthor(content, task.getBizType(), status == 1, remark);
        }
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(), action,
                "automod:" + task.getBizType() + ":" + task.getBizId(),
                remark,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private void notifyCommentTarget(Long targetUserId, ModeratedContentRow content, String region,
                                     String type, String title, String linkUrl) {
        if (targetUserId != null && !targetUserId.equals(content.getUserId())) {
            notificationService.create(targetUserId, content.getUserId(), region, type, title,
                    preview(content.getContent()), linkUrl);
        }
    }

    private void notifyModeratedContentAuthor(ModeratedContentRow content, int bizType,
                                               boolean approved, String remark) {
        String link = switch (bizType) {
            case REVIEW_COMMENT_BIZ_TYPE -> "/reviews/" + content.getRelatedId();
            case POST_COMMENT_BIZ_TYPE -> "/community/posts/" + content.getRelatedId();
            case QA_QUESTION_BIZ_TYPE -> "/shops/" + content.getRelatedId();
            case QA_ANSWER_BIZ_TYPE -> {
                ShopQuestionRow question = qaMapper.selectQuestionByIdForAudit(content.getRelatedId());
                yield question == null ? "/" : "/shops/" + question.getShopId();
            }
            default -> "/";
        };
        notificationService.create(
                content.getUserId(),
                content.getRegion(),
                "automod.audit.result",
                approved ? "内容已通过审核" : "内容未通过审核",
                approved ? "你的内容已公开展示" : "你的内容未通过审核" + (StringUtils.hasText(remark) ? "：" + remark : ""),
                link + (link.contains("?") ? "&" : "?") + "audit=" + (approved ? "approved" : "rejected")
        );
    }

    private void notifyMessageReceiver(MessageRow row) {
        Runnable send = () -> notificationSessions.sendAllRegions(
                row.getToUserId(),
                Map.of("type", "message.new", "data", new MessageResponse(
                        row.getId(), row.getConversationId(), row.getFromUserId(), row.getToUserId(), row.getContent(),
                        row.getStatus(), row.isRead(), formatDateTime(row.getReadAt()), formatDateTime(row.getCreatedAt())))
        );
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    send.run();
                }
            });
        } else {
            send.run();
        }
    }

    private void notifyReviewAuditResult(ReviewRow review, boolean approved, String remark) {
        if (review == null || review.getUserId() == null) {
            return;
        }
        String shopName = StringUtils.hasText(review.getShopName()) ? review.getShopName() : "门店";
        String title = approved ? "点评已通过审核" : "点评未通过审核";
        String content = shopName
                + (approved ? " · 你的点评已公开展示" : " · 你的点评未通过审核")
                + (StringUtils.hasText(remark) ? "：" + remark : "");
        String linkUrl = "/user/reviews/" + review.getId() + "?audit=" + (approved ? "approved" : "rejected");
        String region = StringUtils.hasText(review.getRegion())
                ? review.getRegion()
                : currentRegion().name();
        notificationService.create(
                review.getUserId(),
                region,
                REVIEW_AUDIT_RESULT_TYPE,
                title,
                content,
                linkUrl
        );
    }

    private AdminAuditTaskResponse passDealTask(
            AuditTaskRow task,
            AdminAuditPassRequest request,
            String requestIp
    ) {
        String remark = normalizeRemark(request.getRemark());
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 1, currentAdmin().adminId(), remark) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        if (adminAuditMapper.updateDealAuditDecision(task.getBizId(), currentRegion().name(), 1, "") == 0) {
            throw new NotFoundException("团购不存在或已重新提交");
        }
        publishDealSearchChange(task.getBizId());
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_deal_pass",
                "deal:" + task.getBizId(),
                remark,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse decidePostTask(AuditTaskRow task,
                                                   int status,
                                                   String remark,
                                                   String action,
                                                   String requestIp) {
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), status, currentAdmin().adminId(), remark) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        if (adminAuditMapper.updatePostAuditDecision(task.getBizId(), currentRegion().name(), status,
                status == 1 ? "" : remark) == 0) {
            throw new NotFoundException("帖子不存在或已重新提交");
        }
        if (status == 2) {
            adminAuditMapper.invalidatePendingCommentAuditTasksByContent(
                    POST_COMMENT_BIZ_TYPE, task.getBizId(), "任务失效：帖子未通过审核"
            );
        }
        circleMapper.refreshPostCountByPostId(task.getBizId());
        topicService.refreshPostCountsByPostId(task.getBizId());
        PostRow post = communityMapper.selectPostById(task.getBizId(), currentRegion().name());
        if (status == 1 && post != null && post.getUserId() != null) {
            mentionNotificationService.notifyMentionedUsers(
                    post.getUserId(),
                    post.getRegion(),
                    post.getContent(),
                    "有人@了你",
                    post.getUserName() + " 在帖子《" + preview(post.getTitle()) + "》中提到了你",
                    "/community/posts/" + post.getId()
            );
            topicUpdateNotificationService.notifyTopicFollowers(post);
        }
        notifyPostAuditResult(post, status == 1, remark);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                action,
                "post:" + task.getBizId(),
                remark,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private void notifyPostAuditResult(PostRow post, boolean approved, String remark) {
        if (post == null || post.getUserId() == null) {
            return;
        }
        String titleText = StringUtils.hasText(post.getTitle()) ? post.getTitle() : "你的帖子";
        String title = approved ? "帖子已通过审核" : "帖子未通过审核";
        String content = "《" + titleText + "》"
                + (approved ? " 已公开" : " 未通过审核")
                + (StringUtils.hasText(remark) ? "：" + remark : "");
        String linkUrl = approved
                ? "/community/posts/" + post.getId() + "?audit=approved"
                : "/community/posts/" + post.getId() + "?audit=rejected";
        String region = StringUtils.hasText(post.getRegion())
                ? post.getRegion()
                : currentRegion().name();
        notificationService.create(
                post.getUserId(),
                region,
                POST_AUDIT_RESULT_TYPE,
                title,
                content,
                linkUrl
        );
    }

    private AdminAuditTaskResponse passShopChangeTask(
            AuditTaskRow task,
            AdminAuditPassRequest request,
            String requestIp
    ) {
        ShopChangeRow change = merchantShopChangeService.pendingChangeForAudit(
                task.getBizId(), currentRegion().name());
        if (change == null) {
            throw new NotFoundException("门店变更不存在或已重新提交");
        }
        if (change.getChangeType() == null || (change.getChangeType() != 1 && change.getChangeType() != 2)) {
            throw new IllegalArgumentException("门店变更类型不受支持");
        }
        merchantShopChangeService.requireActiveReferences(
                change.getCategoryId(), change.getCityId(), change.getAreaId());
        if (change.getChangeType() == 2) {
            merchantShopChangeService.validateExistingShopVersion(change);
        }
        String remark = normalizeRemark(request.getRemark());
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 1, currentAdmin().adminId(), remark) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        Long shopId = change.getChangeType() == 1
                ? merchantShopChangeService.applyNewShop(change, currentAdmin().adminId())
                : merchantShopChangeService.applyExistingShop(change, currentAdmin().adminId());
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(shopId));
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_shop_change_pass",
                "shop_change:" + change.getId(),
                remark,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse rejectShopChangeTask(
            AuditTaskRow task,
            AdminAuditRejectRequest request,
            String requestIp
    ) {
        ShopChangeRow change = merchantShopChangeService.pendingChangeForAudit(
                task.getBizId(), currentRegion().name());
        if (change == null) {
            throw new NotFoundException("门店变更不存在或已重新提交");
        }
        String reason = request.getReason().trim();
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 2, currentAdmin().adminId(), reason) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        merchantShopChangeService.rejectChange(change, currentAdmin().adminId(), reason);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_shop_change_reject",
                "shop_change:" + change.getId(),
                reason,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse passReviewAppealTask(
            AuditTaskRow task,
            AdminAuditPassRequest request,
            String requestIp
    ) {
        MerchantReviewAppealRow appeal = merchantReviewService.pendingAppealForAudit(
                task.getBizId(), currentRegion().name());
        if (appeal == null) {
            throw new NotFoundException("点评申诉不存在或已重新提交");
        }
        String remark = normalizeRemark(request.getRemark());
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 1, currentAdmin().adminId(), remark) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        Long shopId = merchantReviewService.passAppeal(appeal, currentAdmin().adminId(), remark);
        reviewMapper.resolvePendingReviewReports(appeal.getReviewId());
        adminAuditMapper.invalidatePendingAuditTasksByBiz(
                REVIEW_BIZ_TYPE, appeal.getReviewId(), "任务失效：商户申诉已通过"
        );
        reviewService.recalculateShopAggregate(shopId);
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(shopId));
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_review_appeal_pass",
                "review_appeal:" + appeal.getId(),
                remark,
                normalizeIp(requestIp)
        );
        ReviewRow review = reviewMapper.selectReviewById(appeal.getReviewId());
        notifyReviewHiddenByMerchantAppeal(review, remark);
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private void notifyReviewHiddenByMerchantAppeal(ReviewRow review, String remark) {
        if (review == null || review.getUserId() == null || review.getUserId() <= 0) {
            return;
        }
        String shopName = StringUtils.hasText(review.getShopName()) ? review.getShopName() : "门店";
        String content = shopName + " · 商户申诉成立，你的点评已从公开展示中隐藏"
                + (StringUtils.hasText(remark) ? "：" + remark : "");
        String linkUrl = "/user/reviews/" + review.getId() + "?hidden=appeal";
        String region = StringUtils.hasText(review.getRegion())
                ? review.getRegion()
                : currentRegion().name();
        notificationService.create(
                review.getUserId(),
                region,
                REVIEW_HIDDEN_TYPE,
                "点评已被隐藏",
                content,
                linkUrl
        );
    }

    private AdminAuditTaskResponse rejectReviewAppealTask(
            AuditTaskRow task,
            AdminAuditRejectRequest request,
            String requestIp
    ) {
        MerchantReviewAppealRow appeal = merchantReviewService.pendingAppealForAudit(
                task.getBizId(), currentRegion().name());
        if (appeal == null) {
            throw new NotFoundException("点评申诉不存在或已重新提交");
        }
        String reason = request.getReason().trim();
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 2, currentAdmin().adminId(), reason) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        merchantReviewService.rejectAppeal(appeal, currentAdmin().adminId(), reason);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_review_appeal_reject",
                "review_appeal:" + appeal.getId(),
                reason,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse passExpertCertificationTask(
            AuditTaskRow task,
            AdminAuditPassRequest request,
            String requestIp
    ) {
        UserExpertCertificationRow certification = userExpertCertificationService.pendingCertificationForAudit(
                task.getBizId(), currentRegion().name());
        if (certification == null) {
            throw new NotFoundException("达人认证申请不存在或已重新提交");
        }
        String remark = normalizeRemark(request.getRemark());
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 1, currentAdmin().adminId(), remark) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        userExpertCertificationService.approveCertification(certification, currentAdmin().adminId(), remark);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_expert_certification_pass",
                "expert_certification:" + certification.getId(),
                remark,
                normalizeIp(requestIp)
        );
        notifyExpertCertificationResult(certification, true, remark);
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse rejectExpertCertificationTask(
            AuditTaskRow task,
            AdminAuditRejectRequest request,
            String requestIp
    ) {
        UserExpertCertificationRow certification = userExpertCertificationService.pendingCertificationForAudit(
                task.getBizId(), currentRegion().name());
        if (certification == null) {
            throw new NotFoundException("达人认证申请不存在或已重新提交");
        }
        String reason = request.getReason().trim();
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 2, currentAdmin().adminId(), reason) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        userExpertCertificationService.rejectCertification(certification, currentAdmin().adminId(), reason);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_expert_certification_reject",
                "expert_certification:" + certification.getId(),
                reason,
                normalizeIp(requestIp)
        );
        notifyExpertCertificationResult(certification, false, reason);
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private void notifyExpertCertificationResult(
            UserExpertCertificationRow certification,
            boolean approved,
            String remark
    ) {
        if (certification == null || certification.getUserId() == null) {
            return;
        }
        String title = approved ? "达人认证已通过" : "达人认证未通过";
        String content = approved
                ? "你的本地达人认证已通过，公开资料现可展示达人标识"
                : "你的本地达人认证未通过";
        if (StringUtils.hasText(remark)) {
            content = content + "：" + remark;
        }
        String linkUrl = "/user/profile?expert=" + (approved ? "approved" : "rejected");
        String region = StringUtils.hasText(certification.getRegion())
                ? certification.getRegion()
                : currentRegion().name();
        notificationService.create(
                certification.getUserId(),
                region,
                EXPERT_CERT_RESULT_TYPE,
                title,
                content,
                linkUrl
        );
    }

    private AdminAuditTaskResponse passMerchantVerificationTask(
            AuditTaskRow task,
            AdminAuditPassRequest request,
            String requestIp
    ) {
        MerchantVerificationRow verification = merchantVerificationService.pendingVerificationForAudit(
                task.getBizId(), currentRegion().name());
        if (verification == null) {
            throw new NotFoundException("认证商户申请不存在或已重新提交");
        }
        String remark = normalizeRemark(request.getRemark());
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 1, currentAdmin().adminId(), remark) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        merchantVerificationService.approveVerification(verification, currentAdmin().adminId(), remark);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_merchant_verification_pass",
                "merchant_verification:" + verification.getId(),
                remark,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse rejectMerchantVerificationTask(
            AuditTaskRow task,
            AdminAuditRejectRequest request,
            String requestIp
    ) {
        MerchantVerificationRow verification = merchantVerificationService.pendingVerificationForAudit(
                task.getBizId(), currentRegion().name());
        if (verification == null) {
            throw new NotFoundException("认证商户申请不存在或已重新提交");
        }
        String reason = request.getReason().trim();
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 2, currentAdmin().adminId(), reason) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        merchantVerificationService.rejectVerification(verification, currentAdmin().adminId(), reason);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_merchant_verification_reject",
                "merchant_verification:" + verification.getId(),
                reason,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse passUserAppealTask(
            AuditTaskRow task,
            AdminAuditPassRequest request,
            String requestIp
    ) {
        UserBanAppealRow appeal = userBanAppealService.pendingAppealForAudit(
                task.getBizId(), currentRegion().name());
        if (appeal == null) {
            throw new NotFoundException("用户申诉不存在或已处理");
        }
        String remark = normalizeRemark(request.getRemark());
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 1, currentAdmin().adminId(), remark) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        userBanAppealService.approveAppeal(appeal, currentAdmin().adminId());
        adminAppUserMapper.updateUserStatus(
                appeal.getUserId(),
                AdminAppUserService.STATUS_BANNED,
                AdminAppUserService.STATUS_NORMAL
        );
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_user_appeal_pass",
                "user_appeal:" + appeal.getId(),
                remark,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse rejectUserAppealTask(
            AuditTaskRow task,
            AdminAuditRejectRequest request,
            String requestIp
    ) {
        UserBanAppealRow appeal = userBanAppealService.pendingAppealForAudit(
                task.getBizId(), currentRegion().name());
        if (appeal == null) {
            throw new NotFoundException("用户申诉不存在或已处理");
        }
        String reason = request.getReason().trim();
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 2, currentAdmin().adminId(), reason) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        userBanAppealService.rejectAppeal(appeal, currentAdmin().adminId(), reason);
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_user_appeal_reject",
                "user_appeal:" + appeal.getId(),
                reason,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private AdminAuditTaskResponse rejectDealTask(
            AuditTaskRow task,
            AdminAuditRejectRequest request,
            String requestIp
    ) {
        String reason = request.getReason().trim();
        if (adminAuditMapper.updateAuditTaskDecision(task.getId(), 2, currentAdmin().adminId(), reason) == 0) {
            throw new IllegalArgumentException("审核任务状态已变更");
        }
        if (adminAuditMapper.updateDealAuditDecision(task.getBizId(), currentRegion().name(), 2, reason) == 0) {
            throw new NotFoundException("团购不存在或已重新提交");
        }
        publishDealSearchChange(task.getBizId());
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_deal_reject",
                "deal:" + task.getBizId(),
                reason,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
    }

    private void publishDealSearchChange(Long dealId) {
        Long shopId = adminAuditMapper.selectDealShopId(dealId, currentRegion().name());
        if (shopId == null) throw new NotFoundException("团购不存在");
        applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(shopId));
    }

    private AuditTaskRow requirePendingTask(Long taskId) {
        AuditTaskRow row = adminAuditMapper.selectAuditTaskById(taskId);
        if (row == null) {
            throw new NotFoundException("审核任务不存在");
        }
        if (!currentRegion().name().equals(row.getRegion())) {
            throw new NotFoundException("审核任务不存在");
        }
        if (row.getBizType() == null || (row.getBizType() != REVIEW_BIZ_TYPE
                && row.getBizType() != DEAL_BIZ_TYPE
                && row.getBizType() != POST_BIZ_TYPE
                && row.getBizType() != SHOP_CHANGE_BIZ_TYPE
                && row.getBizType() != REVIEW_APPEAL_BIZ_TYPE
                && row.getBizType() != EXPERT_CERTIFICATION_BIZ_TYPE
                && row.getBizType() != USER_APPEAL_BIZ_TYPE
                && row.getBizType() != MERCHANT_VERIFICATION_BIZ_TYPE
                && !isModeratedBizType(row.getBizType()))) {
            throw new IllegalArgumentException("当前不支持此审核任务");
        }
        if (row.getStatus() == null || row.getStatus() != 0) {
            throw new IllegalArgumentException("审核任务已处理");
        }
        return row;
    }

    private AuditTaskRow requireModeratedPendingTask(Long taskId) {
        AuditTaskRow task = requirePendingTask(taskId);
        if (!isModeratedBizType(task.getBizType())) {
            throw new IllegalArgumentException("当前任务不支持认领");
        }
        requireAuditPermission(task.getBizType(), true);
        return task;
    }

    private void requireClaimOwner(AuditTaskRow task) {
        Long currentAdminId = currentAdmin().adminId();
        if (!currentAdminId.equals(task.getClaimedByAdminId())) {
            throw new ConflictException("请先认领该任务后再审核");
        }
    }

    private List<Integer> allowedBizTypes(boolean write) {
        AdminSession session = currentAdmin();
        return List.of(
                        DEAL_BIZ_TYPE,
                        REVIEW_BIZ_TYPE,
                        POST_BIZ_TYPE,
                        SHOP_CHANGE_BIZ_TYPE,
                        REVIEW_APPEAL_BIZ_TYPE,
                        EXPERT_CERTIFICATION_BIZ_TYPE,
                        USER_APPEAL_BIZ_TYPE,
                        MERCHANT_VERIFICATION_BIZ_TYPE,
                        REVIEW_COMMENT_BIZ_TYPE,
                        POST_COMMENT_BIZ_TYPE,
                        QA_QUESTION_BIZ_TYPE,
                        QA_ANSWER_BIZ_TYPE,
                        MESSAGE_BIZ_TYPE
                )
                .stream()
                .filter(bizType -> session.permissions().contains(permissionFor(bizType, write)))
                .toList();
    }

    private void requireAuditPermission(Integer bizType, boolean write) {
        permissionChecker.require(currentAdmin(), permissionFor(bizType, write), false);
    }

    private String permissionFor(Integer bizType, boolean write) {
        String action = write ? "write" : "read";
        return switch (bizType == null ? 0 : bizType) {
            case DEAL_BIZ_TYPE -> "audit:deal:" + action;
            case REVIEW_BIZ_TYPE -> "audit:review:" + action;
            case POST_BIZ_TYPE -> "audit:post:" + action;
            case SHOP_CHANGE_BIZ_TYPE -> "audit:shop_change:" + action;
            case REVIEW_APPEAL_BIZ_TYPE -> "audit:review_appeal:" + action;
            case EXPERT_CERTIFICATION_BIZ_TYPE -> "audit:expert_certification:" + action;
            case USER_APPEAL_BIZ_TYPE -> "audit:user_appeal:" + action;
            case MERCHANT_VERIFICATION_BIZ_TYPE -> "audit:merchant_verification:" + action;
            case REVIEW_COMMENT_BIZ_TYPE, POST_COMMENT_BIZ_TYPE, QA_QUESTION_BIZ_TYPE,
                    QA_ANSWER_BIZ_TYPE, MESSAGE_BIZ_TYPE -> "audit:automod:" + action;
            default -> throw new IllegalArgumentException("不支持的审核类型");
        };
    }

    private boolean isModeratedBizType(Integer bizType) {
        return bizType != null && MODERATED_BIZ_TYPES.contains(bizType);
    }

    private AdminAuditTaskResponse toAuditTaskResponse(AuditTaskRow row) {
        return new AdminAuditTaskResponse(
                row.getId(),
                row.getBizType(),
                bizTypeText(row.getBizType()),
                row.getBizId(),
                row.getRegion(),
                row.getStatus(),
                auditStatusText(row.getStatus()),
                row.getShopId(),
                row.getShopName(),
                row.getUserName(),
                row.getReviewContent(),
                row.getRemark(),
                row.getClaimedByAdminId(),
                row.getClaimedByAdminName(),
                formatNullableDateTime(row.getClaimedAt()),
                formatNullableDateTime(row.getClaimExpiresAt()),
                row.getClaimRemainingSeconds(),
                formatDateTime(row.getCreatedAt()),
                row.getAgeSeconds(),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private AdminAuditSlaAlertResponse toSlaAlertResponse(AdminAuditSlaAlertRow row) {
        return new AdminAuditSlaAlertResponse(
                row.getId(),
                row.getRegion(),
                row.getBizType(),
                bizTypeText(row.getBizType()),
                row.getStatus(),
                row.getStatus() != null && row.getStatus() == 1 ? "已恢复" : "进行中",
                row.getPendingCount(),
                row.getOverdueCount(),
                formatNullableDateTime(row.getOldestPendingAt()),
                formatDateTime(row.getFirstOverdueAt()),
                formatDateTime(row.getLastDetectedAt()),
                formatNullableDateTime(row.getResolvedAt())
        );
    }

    private String bizTypeText(Integer bizType) {
        return switch (bizType == null ? 0 : bizType) {
            case 1 -> "商户资质";
            case 2 -> "团购/代金券";
            case 3 -> "点评";
            case 4 -> "帖子";
            case 5 -> "门店变更";
            case 6 -> "商户点评申诉";
            case 7 -> "达人认证";
            case 8 -> "用户封禁申诉";
            case 9 -> "认证商户";
            case REVIEW_COMMENT_BIZ_TYPE -> "点评评论";
            case POST_COMMENT_BIZ_TYPE -> "帖子评论";
            case QA_QUESTION_BIZ_TYPE -> "门店提问";
            case QA_ANSWER_BIZ_TYPE -> "门店回答";
            case MESSAGE_BIZ_TYPE -> "私信";
            default -> "未知";
        };
    }

    private AdminAuditLogResponse toAuditLogResponse(AuditLogRow row) {
        return new AdminAuditLogResponse(
                row.getId(),
                row.getAdminId(),
                safeText(row.getAdminAccount()),
                safeText(row.getAdminName()),
                safeText(row.getAction()),
                safeText(row.getTarget()),
                safeText(row.getDetail()),
                safeText(row.getIp()),
                formatDateTime(row.getCreatedAt())
        );
    }

    private String auditStatusText(Integer status) {
        return switch (status == null ? 0 : status) {
            case 1 -> "通过";
            case 2 -> "驳回";
            default -> "待人审";
        };
    }

    private String preview(String text) {
        if (!StringUtils.hasText(text)) {
            return "";
        }
        String normalized = text.trim();
        return normalized.length() <= 24 ? normalized : normalized.substring(0, 24) + "...";
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private String formatNullableDateTime(LocalDateTime value) {
        return value == null ? null : value.format(DATE_TIME_FORMATTER);
    }

    private String normalizeRemark(String remark) {
        return StringUtils.hasText(remark) ? remark.trim() : "";
    }

    private String normalizeIp(String requestIp) {
        return StringUtils.hasText(requestIp) ? requestIp.trim() : "";
    }

    private String safeText(String value) {
        return value == null ? "" : value;
    }

    private Region currentRegion() {
        return RegionContext.getRegion();
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return session;
    }
}
