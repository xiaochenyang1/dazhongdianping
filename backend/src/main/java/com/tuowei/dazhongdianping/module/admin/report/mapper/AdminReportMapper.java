package com.tuowei.dazhongdianping.module.admin.report.mapper;

import com.tuowei.dazhongdianping.module.admin.report.model.AdminReportRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminReportMapper {

    long countReports(
            @Param("region") String region,
            @Param("reportType") String reportType,
            @Param("status") Integer status,
            @Param("keyword") String keyword
    );

    List<AdminReportRow> selectReports(
            @Param("region") String region,
            @Param("reportType") String reportType,
            @Param("status") Integer status,
            @Param("keyword") String keyword,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    AdminReportRow selectReviewReport(@Param("id") Long id, @Param("region") String region);

    AdminReportRow selectPostReport(@Param("id") Long id, @Param("region") String region);

    AdminReportRow selectMessageReport(@Param("id") Long id);

    AdminReportRow selectReviewCommentReport(@Param("id") Long id, @Param("region") String region);

    AdminReportRow selectPostCommentReport(@Param("id") Long id, @Param("region") String region);

    int resolveReviewReport(@Param("id") Long id, @Param("status") Integer status);

    int resolvePostReport(@Param("id") Long id, @Param("status") Integer status);

    int resolveMessageReport(@Param("id") Long id, @Param("status") Integer status);

    int resolveReviewCommentReport(@Param("id") Long id, @Param("status") Integer status);

    int resolvePostCommentReport(@Param("id") Long id, @Param("status") Integer status);

    int hideReview(@Param("reviewId") Long reviewId, @Param("region") String region, @Param("remark") String remark);

    int hidePost(@Param("postId") Long postId, @Param("region") String region, @Param("remark") String remark);

    int hideReviewComment(@Param("commentId") Long commentId, @Param("region") String region, @Param("remark") String remark);

    int hidePostComment(@Param("commentId") Long commentId, @Param("region") String region, @Param("remark") String remark);

    int resolvePendingReviewReports(@Param("reviewId") Long reviewId);

    int resolvePendingPostReports(@Param("postId") Long postId);

    int resolvePendingReviewCommentReports(@Param("commentId") Long commentId);

    int resolvePendingPostCommentReports(@Param("commentId") Long commentId);

    int refreshReviewCommentCountByCommentId(@Param("commentId") Long commentId);

    int refreshPostCommentCountByCommentId(@Param("commentId") Long commentId);
}
