package com.tuowei.dazhongdianping.module.review.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.auth.certification.service.UserExpertCertificationService;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.review.mapper.ReviewMapper;
import com.tuowei.dazhongdianping.module.review.model.ReviewCommentListQuery;
import com.tuowei.dazhongdianping.module.review.model.ReviewCommentRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewImageRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewLikeRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewListQuery;
import com.tuowei.dazhongdianping.module.review.model.ReviewReportRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.review.model.request.ReviewCommentCreateRequest;
import com.tuowei.dazhongdianping.module.review.model.request.ReviewReportRequest;
import com.tuowei.dazhongdianping.module.review.model.request.ReviewSaveRequest;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewCommentReplyResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewCommentResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewDetailResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewImageResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewLikeResponse;
import com.tuowei.dazhongdianping.module.review.model.response.ReviewReportResponse;
import com.tuowei.dazhongdianping.module.review.model.response.UserReviewSummaryResponse;
import com.tuowei.dazhongdianping.module.review.model.response.MerchantReplyResponse;
import com.tuowei.dazhongdianping.module.merchant.review.model.ReviewMerchantReplyRow;
import com.tuowei.dazhongdianping.module.merchant.review.mapper.MerchantReviewMapper;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class ReviewService {

    private static final int REVIEW_AUDIT_BIZ_TYPE = 3;
    private static final int REVIEW_APPEAL_BIZ_TYPE = 6;
    private static final String EDITED_TASK_INVALID_REMARK = "任务失效：点评已编辑，等待最新版本审核";
    private static final String DELETED_TASK_INVALID_REMARK = "任务失效：点评已删除";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final ReviewMapper reviewMapper;
    private final AuthCommandMapper authCommandMapper;
    private final AdminAuditMapper adminAuditMapper;
    private final UserGrowthService userGrowthService;
    private final MerchantReviewMapper merchantReviewMapper;
    private final NotificationService notificationService;
    private final UserExpertCertificationService userExpertCertificationService;

    public ReviewService(ReviewMapper reviewMapper,
                         AuthCommandMapper authCommandMapper,
                         AdminAuditMapper adminAuditMapper,
                         UserGrowthService userGrowthService,
                         MerchantReviewMapper merchantReviewMapper,
                         NotificationService notificationService,
                         UserExpertCertificationService userExpertCertificationService) {
        this.reviewMapper = reviewMapper;
        this.authCommandMapper = authCommandMapper;
        this.adminAuditMapper = adminAuditMapper;
        this.userGrowthService = userGrowthService;
        this.merchantReviewMapper = merchantReviewMapper;
        this.notificationService = notificationService;
        this.userExpertCertificationService = userExpertCertificationService;
    }

    @Transactional
    public ReviewDetailResponse createReview(ReviewSaveRequest request) {
        AppUserRow currentUser = currentUserRow();
        ensureShopExists(currentRegion().name(), request.getShopId());

        ReviewRow row = new ReviewRow();
        row.setUserId(currentUser.getId());
        row.setShopId(request.getShopId());
        row.setRegion(currentRegion().name());
        row.setUserName(resolveUserName(currentUser));
        row.setContent(request.getContent().trim());
        row.setScoreOverall(normalizeScore(request.getScoreOverall()));
        row.setScoreTaste(normalizeScore(request.getScoreTaste()));
        row.setScoreEnv(normalizeScore(request.getScoreEnv()));
        row.setScoreService(normalizeScore(request.getScoreService()));
        row.setCost(request.getCost().setScale(2, RoundingMode.HALF_UP));
        row.setCurrency(normalizeCurrency(request.getCurrency(), row.getRegion()));
        row.setLikeCount(0);
        row.setCommentCount(0);
        row.setAuditStatus(0);
        row.setAuditRemark("");
        row.setStatus(1);
        row.setTags(joinTags(request.getTags()));
        reviewMapper.insertReview(row);

        boolean hasReviewImages = replaceReviewImages(row.getId(), request.getImages());
        createAuditTask(row.getId(), row.getRegion(), 0, "");
        userGrowthService.rewardForCreatedReview(currentUser.getId(), row.getId());
        if (hasReviewImages) {
            userGrowthService.rewardForReviewImage(currentUser.getId(), row.getId());
        }

        return getOwnedReviewDetail(row.getId(), currentUser.getId());
    }

    public ReviewDetailResponse getPublicReviewDetail(Long reviewId) {
        ReviewRow row = reviewMapper.selectPublicReviewById(reviewId, currentRegion().name());
        if (row == null) {
            throw new NotFoundException("点评不存在");
        }
        Long currentUserId = currentUserIdOrNull();
        return toReviewDetailResponse(
                row,
                reviewMapper.selectReviewImages(reviewId),
                currentUserId != null && reviewMapper.countUserReviewLike(reviewId, currentUserId) > 0
        );
    }

    public ReviewDetailResponse getOwnedReviewDetail(Long reviewId) {
        return getOwnedReviewDetail(reviewId, currentUserSession().userId());
    }

    @Transactional
    public ReviewLikeResponse toggleLike(Long reviewId) {
        UserSession session = currentUserSession();
        ReviewRow review = requirePublicReview(reviewId);
        boolean liked = reviewMapper.countUserReviewLike(reviewId, session.userId()) > 0;
        if (liked) {
            reviewMapper.deleteReviewLike(reviewId, session.userId());
        } else {
            ReviewLikeRow row = new ReviewLikeRow();
            row.setReviewId(reviewId);
            row.setUserId(session.userId());
            reviewMapper.insertReviewLike(row);
            if (review.getUserId() != null
                    && review.getUserId() > 0
                    && !session.userId().equals(review.getUserId())) {
                userGrowthService.rewardForReviewLiked(review.getUserId(), reviewId);
                notificationService.create(review.getUserId(), session.userId(), review.getRegion(), "review.like", "点评获赞",
                        currentUserName() + " 赞了你的点评：" + preview(review.getContent()),
                        "/reviews/" + reviewId);
            }
        }
        refreshInteractionCounts(reviewId);
        return new ReviewLikeResponse(
                reviewId,
                !liked,
                reviewMapper.countReviewLikes(reviewId)
        );
    }

    @Transactional
    public ReviewCommentResponse createComment(Long reviewId, ReviewCommentCreateRequest request) {
        AppUserRow currentUser = currentUserRow();
        ReviewRow review = requirePublicReview(reviewId);
        ReviewCommentThreadTarget threadTarget = resolveReviewCommentThread(reviewId, request.getReplyTo());

        ReviewCommentRow row = new ReviewCommentRow();
        row.setReviewId(reviewId);
        row.setUserId(currentUser.getId());
        row.setUserName(resolveUserName(currentUser));
        row.setContent(request.getContent().trim());
        row.setParentId(threadTarget.parentId());
        row.setReplyTo(threadTarget.replyToId());
        row.setStatus(1);
        row.setCreatedAt(LocalDateTime.now());
        reviewMapper.insertReviewComment(row);
        refreshInteractionCounts(reviewId);
        if (review.getUserId() != null
                && review.getUserId() > 0
                && !currentUser.getId().equals(review.getUserId())) {
            notificationService.create(review.getUserId(), currentUser.getId(), review.getRegion(), "review.comment", "点评新评论",
                    row.getUserName() + " 评论了你的点评：" + preview(row.getContent()),
                    "/reviews/" + reviewId);
        }

        return toReviewCommentResponse(row, currentUser.getId(), threadTarget.replyTo(), List.of());
    }

    public PageResult<ReviewCommentResponse> listComments(Long reviewId, ReviewCommentListQuery query) {
        requirePublicReview(reviewId);
        query.setReviewId(reviewId);
        query.normalize();
        long total = reviewMapper.countPublicRootReviewComments(reviewId);
        Long currentUserId = currentUserIdOrNull();
        List<ReviewCommentRow> rootRows = reviewMapper.selectPublicRootReviewComments(query);
        if (rootRows.isEmpty()) {
            return new PageResult<>(List.of(), total, query.getPage(), query.getPageSize(), false);
        }

        List<Long> parentIds = rootRows.stream().map(ReviewCommentRow::getId).toList();
        Map<Long, List<ReviewCommentResponse>> repliesByParent = new LinkedHashMap<>();
        for (ReviewCommentRow row : reviewMapper.selectPublicReviewCommentReplies(reviewId, parentIds)) {
            repliesByParent.computeIfAbsent(row.getParentId(), ignored -> new ArrayList<>())
                    .add(toReviewCommentResponse(row, currentUserId, toReviewCommentReplyResponse(row), List.of()));
        }

        List<ReviewCommentResponse> items = rootRows.stream()
                .map(row -> toReviewCommentResponse(
                        row,
                        currentUserId,
                        null,
                        repliesByParent.getOrDefault(row.getId(), List.of())))
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    @Transactional
    public ReviewReportResponse reportReview(Long reviewId, ReviewReportRequest request) {
        AppUserRow currentUser = currentUserRow();
        ReviewRow review = requirePublicReview(reviewId);
        if (reviewMapper.selectReviewReportByReporter(reviewId, currentUser.getId()) != null) {
            throw new IllegalArgumentException("你已经举报过这条点评了");
        }

        ReviewReportRow reportRow = new ReviewReportRow();
        reportRow.setReviewId(reviewId);
        reportRow.setReporterUserId(currentUser.getId());
        reportRow.setReporterUserName(resolveUserName(currentUser));
        reportRow.setReason(request.getReason().trim());
        reportRow.setStatus(0);
        reportRow.setCreatedAt(LocalDateTime.now());
        reviewMapper.insertReviewReport(reportRow);

        if (adminAuditMapper.selectPendingAuditTaskByBiz(REVIEW_AUDIT_BIZ_TYPE, reviewId) == null) {
            createAuditTask(reviewId, review.getRegion(), 2, "用户举报：" + request.getReason().trim());
        }

        return new ReviewReportResponse(
                reportRow.getId(),
                reviewId,
                reportRow.getReason(),
                reportRow.getStatus(),
                reportStatusText(reportRow.getStatus()),
                formatDateTime(reportRow.getCreatedAt())
        );
    }

    public PageResult<UserReviewSummaryResponse> listUserReviews(ReviewListQuery query) {
        UserSession session = currentUserSession();
        query.setUserId(session.userId());
        query.setRegion(currentRegion().name());
        query.normalize();
        long total = reviewMapper.countUserReviews(query);
        List<UserReviewSummaryResponse> items = reviewMapper.selectUserReviews(query).stream()
                .map(this::toUserReviewSummaryResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    @Transactional
    public ReviewDetailResponse updateReview(Long reviewId, ReviewSaveRequest request) {
        AppUserRow currentUser = currentUserRow();
        ReviewRow existing = requireOwnedReview(reviewId, currentUser.getId());
        if (!existing.getShopId().equals(request.getShopId())) {
            throw new IllegalArgumentException("点评所属门店不可修改");
        }
        ensureShopExists(existing.getRegion(), existing.getShopId());
        boolean wasPublic = isPublicReview(existing);
        adminAuditMapper.invalidatePendingAuditTasksByBiz(
                REVIEW_AUDIT_BIZ_TYPE,
                reviewId,
                EDITED_TASK_INVALID_REMARK
        );
        invalidateMerchantAppealsForReview(reviewId, EDITED_TASK_INVALID_REMARK);

        ReviewRow updated = new ReviewRow();
        updated.setId(existing.getId());
        updated.setUserId(existing.getUserId());
        updated.setShopId(existing.getShopId());
        updated.setRegion(existing.getRegion());
        updated.setUserName(resolveUserName(currentUser));
        updated.setContent(request.getContent().trim());
        updated.setScoreOverall(normalizeScore(request.getScoreOverall()));
        updated.setScoreTaste(normalizeScore(request.getScoreTaste()));
        updated.setScoreEnv(normalizeScore(request.getScoreEnv()));
        updated.setScoreService(normalizeScore(request.getScoreService()));
        updated.setCost(request.getCost().setScale(2, RoundingMode.HALF_UP));
        updated.setCurrency(normalizeCurrency(request.getCurrency(), existing.getRegion()));
        updated.setAuditStatus(0);
        updated.setAuditRemark("");
        updated.setStatus(existing.getStatus() == null ? 1 : existing.getStatus());
        updated.setTags(joinTags(request.getTags()));

        int affected = reviewMapper.updateReview(updated);
        if (affected == 0) {
            throw new NotFoundException("点评不存在");
        }

        reviewMapper.deleteReviewImagesByReviewId(reviewId);
        boolean hasReviewImages = replaceReviewImages(reviewId, request.getImages());
        createAuditTask(reviewId, existing.getRegion(), 0, "");
        if (hasReviewImages) {
            userGrowthService.rewardForReviewImage(currentUser.getId(), reviewId);
        }

        if (wasPublic) {
            recalculateShopAggregate(existing.getShopId());
        }

        return getOwnedReviewDetail(reviewId, currentUser.getId());
    }

    @Transactional
    public void deleteReview(Long reviewId) {
        ReviewRow existing = requireOwnedReview(reviewId, currentUserSession().userId());
        adminAuditMapper.invalidatePendingAuditTasksByBiz(
                REVIEW_AUDIT_BIZ_TYPE,
                reviewId,
                DELETED_TASK_INVALID_REMARK
        );
        invalidateMerchantAppealsForReview(reviewId, DELETED_TASK_INVALID_REMARK);
        int affected = reviewMapper.softDeleteReview(reviewId, currentUserSession().userId());
        if (affected == 0) {
            throw new NotFoundException("点评不存在");
        }
        reviewMapper.resolvePendingReviewReports(reviewId);
        if (isPublicReview(existing)) {
            recalculateShopAggregate(existing.getShopId());
        }
    }

    @Transactional
    public void recalculateShopAggregate(Long shopId) {
        List<ReviewRow> rows = reviewMapper.selectApprovedReviewsForAggregation(shopId);
        if (rows.isEmpty()) {
            reviewMapper.updateShopReviewAggregate(
                    shopId,
                    BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP),
                    BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP),
                    BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP),
                    BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP),
                    0
            );
            return;
        }

        BigDecimal overall = average(rows, ReviewRow::getScoreOverall);
        BigDecimal taste = average(rows, ReviewRow::getScoreTaste);
        BigDecimal env = average(rows, ReviewRow::getScoreEnv);
        BigDecimal service = average(rows, ReviewRow::getScoreService);

        reviewMapper.updateShopReviewAggregate(shopId, overall, taste, env, service, rows.size());
    }

    public void invalidateMerchantAppealsForReview(Long reviewId, String remark) {
        List<Long> appealIds = merchantReviewMapper.selectActiveAppealIdsByReview(reviewId);
        for (Long appealId : appealIds) {
            adminAuditMapper.invalidatePendingAuditTasksByBiz(REVIEW_APPEAL_BIZ_TYPE, appealId, remark);
        }
        merchantReviewMapper.invalidateActiveAppealsByReview(reviewId, remark);
    }

    private BigDecimal average(List<ReviewRow> rows, ScoreExtractor extractor) {
        BigDecimal total = BigDecimal.ZERO;
        for (ReviewRow row : rows) {
            total = total.add(extractor.getScore(row));
        }
        return total.divide(BigDecimal.valueOf(rows.size()), 1, RoundingMode.HALF_UP);
    }

    private ReviewDetailResponse getOwnedReviewDetail(Long reviewId, Long userId) {
        ReviewRow row = requireOwnedReview(reviewId, userId);
        return toReviewDetailResponse(
                row,
                reviewMapper.selectReviewImages(reviewId),
                reviewMapper.countUserReviewLike(reviewId, userId) > 0
        );
    }

    private ReviewRow requireOwnedReview(Long reviewId, Long userId) {
        ReviewRow row = reviewMapper.selectOwnedReviewById(reviewId, userId, currentRegion().name());
        if (row == null) {
            throw new NotFoundException("点评不存在");
        }
        return row;
    }

    private ReviewRow requirePublicReview(Long reviewId) {
        ReviewRow row = reviewMapper.selectPublicReviewById(reviewId, currentRegion().name());
        if (row == null) {
            throw new NotFoundException("点评不存在");
        }
        return row;
    }

    private AppUserRow currentUserRow() {
        UserSession session = currentUserSession();
        AppUserRow row = authCommandMapper.selectUserById(session.userId());
        if (row == null || row.getStatus() == null || row.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }
        return row;
    }

    private UserSession currentUserSession() {
        UserSession session = UserSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return session;
    }

    private void ensureShopExists(String region, Long shopId) {
        if (reviewMapper.countAvailableShop(region, shopId) == 0) {
            throw new IllegalArgumentException("门店不存在或不可点评");
        }
    }

    private boolean replaceReviewImages(Long reviewId, List<String> images) {
        if (images == null || images.isEmpty()) {
            return false;
        }
        boolean inserted = false;
        int sortNo = 1;
        for (String image : images) {
            if (!StringUtils.hasText(image)) {
                continue;
            }
            ReviewImageRow row = new ReviewImageRow();
            row.setReviewId(reviewId);
            row.setUrl(image.trim());
            row.setMediaType(1);
            row.setSortNo(sortNo++);
            reviewMapper.insertReviewImage(row);
            inserted = true;
        }
        return inserted;
    }

    private void createAuditTask(Long reviewId, String region, int machineResult, String remark) {
        AuditTaskRow row = new AuditTaskRow();
        row.setBizType(REVIEW_AUDIT_BIZ_TYPE);
        row.setBizId(reviewId);
        row.setRegion(region);
        row.setMachineResult(machineResult);
        row.setStatus(0);
        row.setAuditorId(0L);
        row.setRemark(remark);
        adminAuditMapper.insertAuditTask(row);
    }

    private void refreshInteractionCounts(Long reviewId) {
        reviewMapper.updateReviewInteractionCounts(
                reviewId,
                reviewMapper.countReviewLikes(reviewId),
                reviewMapper.countReviewComments(reviewId)
        );
    }

    private ReviewDetailResponse toReviewDetailResponse(ReviewRow row,
                                                        List<ReviewImageRow> imageRows,
                                                        boolean likedByCurrentUser) {
        List<ReviewImageResponse> images = imageRows.stream()
                .map(image -> new ReviewImageResponse(image.getId(), image.getUrl()))
                .toList();
        return new ReviewDetailResponse(
                row.getId(),
                row.getShopId(),
                row.getShopName(),
                row.getUserId(),
                row.getUserName(),
                row.getContent(),
                row.getScoreOverall(),
                row.getScoreTaste(),
                row.getScoreEnv(),
                row.getScoreService(),
                row.getCost(),
                row.getCurrency(),
                row.getLikeCount(),
                row.getCommentCount(),
                likedByCurrentUser,
                row.getAuditStatus(),
                auditStatusText(row.getAuditStatus()),
                row.getAuditRemark(),
                row.getStatus(),
                reviewStatusText(row.getStatus()),
                userExpertCertificationService.approvedBadge(row.getUserId(), row.getRegion()),
                splitTags(row.getTags()),
                images,
                toMerchantReplyResponse(reviewMapper.selectMerchantReply(row.getId())),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private MerchantReplyResponse toMerchantReplyResponse(ReviewMerchantReplyRow row) {
        if (row == null) {
            return null;
        }
        return new MerchantReplyResponse(
                row.getMerchantName(),
                row.getContent(),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private ReviewCommentResponse toReviewCommentResponse(ReviewCommentRow row,
                                                          Long currentUserId,
                                                          ReviewCommentReplyResponse replyTo,
                                                          List<ReviewCommentResponse> replies) {
        return new ReviewCommentResponse(
                row.getId(),
                row.getReviewId(),
                row.getUserId(),
                row.getUserName(),
                row.getContent(),
                row.getParentId() == null ? 0L : row.getParentId(),
                replyTo,
                replies,
                currentUserId != null && currentUserId.equals(row.getUserId()),
                formatDateTime(row.getCreatedAt())
        );
    }

    private ReviewCommentReplyResponse toReviewCommentReplyResponse(ReviewCommentRow row) {
        if (row.getReplyTo() == null || row.getReplyTo() <= 0) {
            return null;
        }
        return new ReviewCommentReplyResponse(
                row.getReplyTo(),
                row.getReplyToUserId(),
                row.getReplyToUserName(),
                row.getReplyToContent()
        );
    }

    private ReviewCommentThreadTarget resolveReviewCommentThread(Long reviewId, Long replyToId) {
        long normalizedReplyTo = replyToId == null ? 0L : replyToId;
        if (normalizedReplyTo <= 0) {
            return new ReviewCommentThreadTarget(0L, 0L, null);
        }
        ReviewCommentRow replyTarget = reviewMapper.selectPublicReviewCommentById(reviewId, normalizedReplyTo);
        if (replyTarget == null) {
            throw new IllegalArgumentException("回复目标不存在");
        }
        Long parentId = replyTarget.getParentId() != null && replyTarget.getParentId() > 0
                ? replyTarget.getParentId()
                : replyTarget.getId();
        return new ReviewCommentThreadTarget(
                parentId,
                replyTarget.getId(),
                new ReviewCommentReplyResponse(
                        replyTarget.getId(),
                        replyTarget.getUserId(),
                        replyTarget.getUserName(),
                        replyTarget.getContent()
                )
        );
    }

    private UserReviewSummaryResponse toUserReviewSummaryResponse(ReviewRow row) {
        return new UserReviewSummaryResponse(
                row.getId(),
                row.getShopId(),
                row.getShopName(),
                row.getContent(),
                row.getScoreOverall(),
                row.getAuditStatus(),
                auditStatusText(row.getAuditStatus()),
                row.getAuditRemark(),
                row.getStatus(),
                reviewStatusText(row.getStatus()),
                splitTags(row.getTags()),
                formatDateTime(row.getCreatedAt()),
                formatDateTime(row.getUpdatedAt())
        );
    }

    private String resolveUserName(AppUserRow userRow) {
        if (StringUtils.hasText(userRow.getNickname())) {
            return userRow.getNickname().trim();
        }
        if (StringUtils.hasText(userRow.getEmail())) {
            return userRow.getEmail().trim();
        }
        if (StringUtils.hasText(userRow.getPhone())) {
            return userRow.getPhone().trim();
        }
        return "匿名用户";
    }

    private BigDecimal normalizeScore(BigDecimal value) {
        if (value == null) {
            return BigDecimal.ZERO.setScale(1, RoundingMode.HALF_UP);
        }
        return value.setScale(1, RoundingMode.HALF_UP);
    }

    private String normalizeCurrency(String currency, String region) {
        if (StringUtils.hasText(currency)) {
            return currency.trim().toUpperCase(Locale.ROOT);
        }
        return "EU".equals(region) ? "EUR" : "CNY";
    }

    private List<String> splitTags(String tags) {
        if (!StringUtils.hasText(tags)) {
            return List.of();
        }
        List<String> values = new ArrayList<>();
        for (String tag : tags.split(",")) {
            if (StringUtils.hasText(tag)) {
                values.add(tag.trim());
            }
        }
        return values;
    }

    private String joinTags(List<String> tags) {
        if (tags == null || tags.isEmpty()) {
            return "";
        }
        return tags.stream()
                .filter(StringUtils::hasText)
                .map(String::trim)
                .reduce((left, right) -> left + "," + right)
                .orElse("");
    }

    private String currentUserName() {
        return resolveUserName(currentUserRow());
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

    private String auditStatusText(Integer auditStatus) {
        return switch (auditStatus == null ? 0 : auditStatus) {
            case 1 -> "通过";
            case 2 -> "驳回";
            default -> "待审";
        };
    }

    private String reviewStatusText(Integer status) {
        return switch (status == null ? 1 : status) {
            case 2 -> "隐藏";
            default -> "正常";
        };
    }

    private String reportStatusText(Integer status) {
        return switch (status == null ? 0 : status) {
            case 1 -> "已处理";
            default -> "待处理";
        };
    }

    private boolean isPublicReview(ReviewRow row) {
        return row != null
                && row.getAuditStatus() != null
                && row.getAuditStatus() == 1
                && row.getStatus() != null
                && row.getStatus() == 1
                && !Boolean.TRUE.equals(row.getIsDeleted());
    }

    private Region currentRegion() {
        return RegionContext.getRegion();
    }

    private Long currentUserIdOrNull() {
        UserSession session = UserSessionContext.get();
        return session == null ? null : session.userId();
    }

    @FunctionalInterface
    private interface ScoreExtractor {
        BigDecimal getScore(ReviewRow row);
    }

    private record ReviewCommentThreadTarget(Long parentId,
                                             Long replyToId,
                                             ReviewCommentReplyResponse replyTo) {
    }
}
