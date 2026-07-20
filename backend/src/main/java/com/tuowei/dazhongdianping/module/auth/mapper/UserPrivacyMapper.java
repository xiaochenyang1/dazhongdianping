package com.tuowei.dazhongdianping.module.auth.mapper;

import com.tuowei.dazhongdianping.module.auth.model.GrowthPointsLogRow;
import com.tuowei.dazhongdianping.module.auth.model.FollowExportRow;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyDeleteTaskRow;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyExportTaskRow;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyTaskQuery;
import com.tuowei.dazhongdianping.module.auth.model.TopicFollowExportRow;
import com.tuowei.dazhongdianping.module.browse.model.SearchHistoryRow;
import com.tuowei.dazhongdianping.module.favorite.model.FavoriteRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.community.model.PostRow;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.apache.ibatis.annotations.Param;

public interface UserPrivacyMapper {

    void insertExportTask(PrivacyExportTaskRow row);

    int updateExportTaskResult(PrivacyExportTaskRow row);

    int updateExportTaskFailure(@Param("id") Long id, @Param("failReason") String failReason);

    int expireReadyExportTasks(@Param("userId") Long userId);

    long countRecentExportTasks(@Param("userId") Long userId, @Param("since") LocalDateTime since);

    long countExportTasks(PrivacyTaskQuery query);

    List<PrivacyExportTaskRow> selectExportTasks(PrivacyTaskQuery query);

    PrivacyExportTaskRow selectExportTaskByIdAndUserId(@Param("taskId") Long taskId, @Param("userId") Long userId);

    PrivacyExportTaskRow selectLatestExportTaskByUserId(@Param("userId") Long userId);

    void insertDeleteTask(PrivacyDeleteTaskRow row);

    PrivacyDeleteTaskRow selectDeleteTaskByIdAndUserId(@Param("taskId") Long taskId, @Param("userId") Long userId);

    PrivacyDeleteTaskRow selectLatestDeleteTaskByUserId(@Param("userId") Long userId);

    PrivacyDeleteTaskRow selectActiveDeleteTaskByUserId(@Param("userId") Long userId);

    PrivacyDeleteTaskRow selectDueDeleteTaskByUserIdForUpdate(@Param("userId") Long userId);

    int cancelDeleteTask(@Param("taskId") Long taskId, @Param("cancelledAt") LocalDateTime cancelledAt);

    int completeDeleteTask(@Param("taskId") Long taskId, @Param("completedAt") LocalDateTime completedAt);

    int deleteSearchHistoryByUserId(@Param("userId") Long userId);

    int deleteGrowthPointsLogsByUserId(@Param("userId") Long userId);

    int deleteVerificationCodesByTarget(@Param("target") String target);

    int disableDevicesByUserId(@Param("userId") Long userId);

    int anonymizeUser(@Param("userId") Long userId, @Param("nickname") String nickname);

    int anonymizeReviews(@Param("userId") Long userId, @Param("nickname") String nickname);

    int anonymizeReviewComments(@Param("userId") Long userId, @Param("nickname") String nickname);

    int anonymizeReviewReports(@Param("userId") Long userId, @Param("nickname") String nickname);
    int anonymizePosts(@Param("userId") Long userId, @Param("nickname") String nickname);
    int anonymizePostComments(@Param("userId") Long userId, @Param("nickname") String nickname);
    int anonymizePostReports(@Param("userId") Long userId, @Param("nickname") String nickname);

    List<ReviewRow> selectReviewsByUserId(@Param("userId") Long userId);
    List<PostRow> selectPostsByUserId(@Param("userId") Long userId);

    List<OrderRow> selectOrdersByUserId(@Param("userId") Long userId);

    List<ReservationRow> selectReservationsByUserId(@Param("userId") Long userId);

    List<FavoriteRow> selectFavoritesByUserId(@Param("userId") Long userId);

    List<GrowthPointsLogRow> selectGrowthPointsLogsByUserId(@Param("userId") Long userId);

    List<SearchHistoryRow> selectSearchHistoryByUserId(@Param("userId") Long userId);
    List<FollowExportRow> selectFollowingForExport(@Param("userId") Long userId);
    List<FollowExportRow> selectFollowersForExport(@Param("userId") Long userId);
    int deleteFollowRelationsByUserId(@Param("userId") Long userId);
    int deleteNotificationsByUserId(@Param("userId") Long userId);
    int anonymizeFollowNotificationsByActor(@Param("userId") Long userId);
    List<Map<String, Object>> selectMessageConversationsForExport(@Param("userId") Long userId);
    List<Map<String, Object>> selectMessagesForExport(@Param("userId") Long userId);
    int deleteMessageBlocksByUserId(@Param("userId") Long userId);
    int anonymizeMessagesByUserId(@Param("userId") Long userId);
    int anonymizeMessageReportsByUserId(@Param("userId") Long userId);
    List<Map<String, Object>> selectCirclesForExport(@Param("userId") Long userId);
    int decrementCircleMemberCountsByUserId(@Param("userId") Long userId);
    int deleteCircleMembershipsByUserId(@Param("userId") Long userId);
    List<TopicFollowExportRow> selectTopicsForExport(@Param("userId") Long userId);
    List<Long> selectFollowedTopicIdsByUserId(@Param("userId") Long userId);
    int deleteTopicFollowsByUserId(@Param("userId") Long userId);
    int refreshTopicFollowerCount(@Param("topicId") Long topicId);
}
