package com.tuowei.dazhongdianping.module.admin.audit.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditLogQuery;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditLogRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditTaskQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditPassRequest;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditRejectRequest;
import com.tuowei.dazhongdianping.module.admin.audit.model.response.AdminAuditLogResponse;
import com.tuowei.dazhongdianping.module.admin.audit.model.response.AdminAuditTaskResponse;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminPermissionChecker;
import com.tuowei.dazhongdianping.module.admin.user.mapper.AdminAppUserMapper;
import com.tuowei.dazhongdianping.module.admin.user.service.AdminAppUserService;
import com.tuowei.dazhongdianping.module.auth.appeal.model.UserBanAppealRow;
import com.tuowei.dazhongdianping.module.auth.appeal.service.UserBanAppealService;
import com.tuowei.dazhongdianping.module.auth.certification.model.UserExpertCertificationRow;
import com.tuowei.dazhongdianping.module.auth.certification.service.UserExpertCertificationService;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.review.mapper.ReviewMapper;
import com.tuowei.dazhongdianping.module.review.service.ReviewService;
import com.tuowei.dazhongdianping.module.circle.mapper.CircleMapper;
import com.tuowei.dazhongdianping.module.community.mapper.CommunityMapper;
import com.tuowei.dazhongdianping.module.community.model.PostRow;
import com.tuowei.dazhongdianping.module.notification.service.MentionNotificationService;
import com.tuowei.dazhongdianping.module.topic.service.TopicService;
import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangeRow;
import com.tuowei.dazhongdianping.module.merchant.shop.service.MerchantShopChangeService;
import com.tuowei.dazhongdianping.module.merchant.review.model.MerchantReviewAppealRow;
import com.tuowei.dazhongdianping.module.merchant.review.service.MerchantReviewService;
import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
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
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AdminAuditMapper adminAuditMapper;
    private final ReviewMapper reviewMapper;
    private final ReviewService reviewService;
    private final MerchantShopChangeService merchantShopChangeService;
    private final MerchantReviewService merchantReviewService;
    private final UserExpertCertificationService userExpertCertificationService;
    private final UserBanAppealService userBanAppealService;
    private final AdminAppUserMapper adminAppUserMapper;
    private final ApplicationEventPublisher applicationEventPublisher;
    private final CircleMapper circleMapper;
    private final CommunityMapper communityMapper;
    private final TopicService topicService;
    private final MentionNotificationService mentionNotificationService;
    private final AdminPermissionChecker permissionChecker;

    public AdminAuditService(AdminAuditMapper adminAuditMapper,
                             ReviewMapper reviewMapper,
                             ReviewService reviewService,
                             MerchantShopChangeService merchantShopChangeService,
                             MerchantReviewService merchantReviewService,
                             UserExpertCertificationService userExpertCertificationService,
                             UserBanAppealService userBanAppealService,
                             AdminAppUserMapper adminAppUserMapper,
                             ApplicationEventPublisher applicationEventPublisher,
                             CircleMapper circleMapper,
                             CommunityMapper communityMapper,
                             TopicService topicService,
                             MentionNotificationService mentionNotificationService,
                             AdminPermissionChecker permissionChecker) {
        this.adminAuditMapper = adminAuditMapper;
        this.reviewMapper = reviewMapper;
        this.reviewService = reviewService;
        this.merchantShopChangeService = merchantShopChangeService;
        this.merchantReviewService = merchantReviewService;
        this.userExpertCertificationService = userExpertCertificationService;
        this.userBanAppealService = userBanAppealService;
        this.adminAppUserMapper = adminAppUserMapper;
        this.applicationEventPublisher = applicationEventPublisher;
        this.circleMapper = circleMapper;
        this.communityMapper = communityMapper;
        this.topicService = topicService;
        this.mentionNotificationService = mentionNotificationService;
        this.permissionChecker = permissionChecker;
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
        long total = adminAuditMapper.countAuditTasks(query);
        List<AdminAuditTaskResponse> items = adminAuditMapper.selectAuditTasks(query).stream()
                .map(this::toAuditTaskResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    @Transactional
    public AdminAuditTaskResponse passTask(Long taskId, AdminAuditPassRequest request, String requestIp) {
        AuditTaskRow task = requirePendingTask(taskId);
        requireAuditPermission(task.getBizType(), true);
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

        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(taskId));
    }

    @Transactional
    public AdminAuditTaskResponse rejectTask(Long taskId, AdminAuditRejectRequest request, String requestIp) {
        AuditTaskRow task = requirePendingTask(taskId);
        requireAuditPermission(task.getBizType(), true);
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

        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(taskId));
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
        if (adminAuditMapper.updateDealAuditDecision(task.getBizId(), currentRegion().name(), 1) == 0) {
            throw new NotFoundException("团购不存在或已重新提交");
        }
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
        circleMapper.refreshPostCountByPostId(task.getBizId());
        topicService.refreshPostCountsByPostId(task.getBizId());
        if (status == 1) {
            PostRow post = communityMapper.selectPublicPost(task.getBizId(), currentRegion().name());
            if (post != null && post.getUserId() != null) {
                mentionNotificationService.notifyMentionedUsers(
                        post.getUserId(),
                        post.getRegion(),
                        post.getContent(),
                        "有人@了你",
                        post.getUserName() + " 在帖子《" + preview(post.getTitle()) + "》中提到了你",
                        "/community/posts/" + post.getId()
                );
            }
        }
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                action,
                "post:" + task.getBizId(),
                remark,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
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
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
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
        if (adminAuditMapper.updateDealAuditDecision(task.getBizId(), currentRegion().name(), 2) == 0) {
            throw new NotFoundException("团购不存在或已重新提交");
        }
        adminAuditMapper.insertAuditLog(
                currentAdmin().adminId(),
                "audit_deal_reject",
                "deal:" + task.getBizId(),
                reason,
                normalizeIp(requestIp)
        );
        return toAuditTaskResponse(adminAuditMapper.selectAuditTaskById(task.getId()));
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
                && row.getBizType() != USER_APPEAL_BIZ_TYPE)) {
            throw new IllegalArgumentException("当前不支持此审核任务");
        }
        if (row.getStatus() == null || row.getStatus() != 0) {
            throw new IllegalArgumentException("审核任务已处理");
        }
        return row;
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
                        USER_APPEAL_BIZ_TYPE
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
            default -> throw new IllegalArgumentException("不支持的审核类型");
        };
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
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
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
