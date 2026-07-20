package com.tuowei.dazhongdianping.module.auth.service;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.auth.model.GrowthPointsLogRow;
import com.tuowei.dazhongdianping.module.auth.model.GrowthRuleRow;
import com.tuowei.dazhongdianping.module.auth.model.UserGrowthRecordQuery;
import com.tuowei.dazhongdianping.module.auth.model.response.UserGrowthRecordResponse;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserGrowthService {

    private static final int GROWTH_TYPE_VALUE = 1;
    private static final int POINTS_TYPE_VALUE = 2;
    private static final String ACTION_REVIEW_CREATE = "review_create";
    private static final String ACTION_REVIEW_LIKED = "review_liked";
    private static final String ACTION_REVIEW_IMAGE = "review_image";
    private static final String ACTION_ORDER_COMPLETE = "order_complete";
    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final AuthCommandMapper authCommandMapper;

    public UserGrowthService(AuthCommandMapper authCommandMapper) {
        this.authCommandMapper = authCommandMapper;
    }

    @Transactional
    public void rewardForCreatedReview(Long userId, Long reviewId) {
        rewardAction(userId, ACTION_REVIEW_CREATE, reviewId);
    }

    @Transactional
    public void rewardForReviewLiked(Long userId, Long reviewId) {
        rewardAction(userId, ACTION_REVIEW_LIKED, reviewId);
    }

    @Transactional
    public void rewardForReviewImage(Long userId, Long reviewId) {
        rewardAction(userId, ACTION_REVIEW_IMAGE, reviewId);
    }

    @Transactional
    public void rewardForCompletedOrder(Long userId, Long orderId) {
        rewardAction(userId, ACTION_ORDER_COMPLETE, orderId);
    }

    private void rewardAction(Long userId, String action, Long bizId) {
        AppUserRow userRow = authCommandMapper.selectUserByIdForUpdate(userId);
        if (userRow == null || userRow.getStatus() == null || userRow.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }
        if (authCommandMapper.countGrowthPointsLogsByAction(userId, action, GROWTH_TYPE_VALUE, bizId) > 0
                || authCommandMapper.countGrowthPointsLogsByAction(userId, action, POINTS_TYPE_VALUE, bizId) > 0) {
            return;
        }

        GrowthRuleRow rule = authCommandMapper.selectEnabledGrowthRule(action);
        if (rule == null) {
            return;
        }
        if (rule.getDailyLimit() != null && rule.getDailyLimit() > 0
                && authCommandMapper.countDailyGrowthActions(userId, action) >= rule.getDailyLimit()) {
            return;
        }

        int growthReward = valueOrZero(rule.getGrowthValue());
        int pointsReward = valueOrZero(rule.getPoints());
        int growthValue = valueOrZero(userRow.getGrowthValue()) + growthReward;
        int points = valueOrZero(userRow.getPoints()) + pointsReward;
        Integer configuredLevel = authCommandMapper.selectLevelByGrowth(growthValue);
        int level = configuredLevel == null ? 1 : configuredLevel;
        int affected = authCommandMapper.updateUserGrowthProfile(userId, growthValue, level, points);
        if (affected != 1) {
            throw new IllegalStateException("用户成长值更新失败");
        }

        insertLog(userId, action, GROWTH_TYPE_VALUE, bizId, growthReward, growthValue, rule.getActionName() + "奖励");
        insertLog(userId, action, POINTS_TYPE_VALUE, bizId, pointsReward, points, rule.getActionName() + "奖励");
    }

    public PageResult<UserGrowthRecordResponse> listCurrentUserGrowthRecords(UserGrowthRecordQuery query) {
        UserSession session = requireUserSession();
        query.setUserId(session.userId());
        query.normalize();
        long total = authCommandMapper.countGrowthPointsLogs(query);
        List<UserGrowthRecordResponse> items = authCommandMapper.selectGrowthPointsLogs(query).stream()
                .map(this::toGrowthRecordResponse)
                .toList();
        return new PageResult<>(items, total, query.getPage(), query.getPageSize(), query.getOffset() + items.size() < total);
    }

    private void insertLog(Long userId,
                           String action,
                           Integer type,
                           Long bizId,
                           int changeAmount,
                           int balanceAfter,
                           String remark) {
        GrowthPointsLogRow row = new GrowthPointsLogRow();
        row.setUserId(userId);
        row.setType(type);
        row.setAction(action);
        row.setBizId(bizId);
        row.setChangeAmount(changeAmount);
        row.setBalanceAfter(balanceAfter);
        row.setRemark(remark);
        row.setCreatedAt(LocalDateTime.now());
        authCommandMapper.insertGrowthPointsLog(row);
    }

    private UserGrowthRecordResponse toGrowthRecordResponse(GrowthPointsLogRow row) {
        return new UserGrowthRecordResponse(
                row.getId(),
                row.getType(),
                typeText(row.getType()),
                row.getAction(),
                actionText(row.getAction()),
                row.getBizId(),
                row.getChangeAmount(),
                row.getBalanceAfter(),
                row.getRemark(),
                formatDateTime(row.getCreatedAt())
        );
    }

    private UserSession requireUserSession() {
        UserSession session = UserSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return session;
    }

    private int valueOrZero(Integer value) {
        return value == null ? 0 : value;
    }

    private String typeText(Integer type) {
        return switch (type == null ? 0 : type) {
            case POINTS_TYPE_VALUE -> "积分";
            case GROWTH_TYPE_VALUE -> "成长值";
            default -> "未知";
        };
    }

    private String actionText(String action) {
        GrowthRuleRow rule = authCommandMapper.selectEnabledGrowthRule(action);
        if (rule != null) {
            return rule.getActionName();
        }
        if (ACTION_REVIEW_CREATE.equals(action)) {
            return "发布点评";
        }
        return "系统奖励";
    }

    private String formatDateTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }
}
