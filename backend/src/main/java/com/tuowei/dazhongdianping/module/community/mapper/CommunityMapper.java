package com.tuowei.dazhongdianping.module.community.mapper;

import com.tuowei.dazhongdianping.module.community.model.PostRow;
import com.tuowei.dazhongdianping.module.community.model.PostCommentRow;
import com.tuowei.dazhongdianping.module.community.model.PostReportRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface CommunityMapper {
    String selectUserName(@Param("userId") Long userId);
    void insertPost(PostRow row);
    void insertPostImage(@Param("postId") Long postId, @Param("url") String url, @Param("sortNo") Integer sortNo);
    void insertPostTopic(@Param("postId") Long postId, @Param("topicId") Long topicId);
    PostRow selectOwnedPost(@Param("postId") Long postId, @Param("userId") Long userId, @Param("region") String region);
    PostRow selectPublicPost(@Param("postId") Long postId, @Param("region") String region);
    List<String> selectPostImages(@Param("postId") Long postId);
    List<String> selectPostTopics(@Param("postId") Long postId);
    long countUserPosts(@Param("userId") Long userId, @Param("region") String region);
    List<PostRow> selectUserPosts(@Param("userId") Long userId, @Param("region") String region,
                                  @Param("limit") Integer limit, @Param("offset") Integer offset);
    long countPublicPosts(@Param("region") String region);
    List<PostRow> selectPublicPosts(@Param("region") String region,
                                    @Param("limit") Integer limit, @Param("offset") Integer offset);
    long countFollowingPosts(@Param("userId") Long userId, @Param("region") String region);
    List<PostRow> selectFollowingPosts(@Param("userId") Long userId, @Param("region") String region,
                                       @Param("limit") Integer limit, @Param("offset") Integer offset);
    long countCirclePosts(@Param("circleId") Long circleId, @Param("region") String region);
    List<PostRow> selectCirclePosts(@Param("circleId") Long circleId, @Param("region") String region,
                                    @Param("limit") Integer limit, @Param("offset") Integer offset);
    long countTopicPosts(@Param("topicId") Long topicId, @Param("region") String region);
    List<PostRow> selectTopicPosts(@Param("topicId") Long topicId, @Param("region") String region,
                                   @Param("limit") Integer limit, @Param("offset") Integer offset);
    int updatePost(PostRow row);
    int deletePostImages(@Param("postId") Long postId);
    int deletePostTopics(@Param("postId") Long postId);
    int softDeletePost(@Param("postId") Long postId, @Param("userId") Long userId, @Param("region") String region);
    int countUserPostLike(@Param("postId") Long postId, @Param("userId") Long userId);
    void insertPostLike(@Param("postId") Long postId, @Param("userId") Long userId);
    int deletePostLike(@Param("postId") Long postId, @Param("userId") Long userId);
    int countPostLikes(@Param("postId") Long postId);
    int refreshPostLikeCount(@Param("postId") Long postId);
    void insertPostComment(PostCommentRow row);
    long countPostComments(@Param("postId") Long postId);
    List<PostCommentRow> selectPostComments(@Param("postId") Long postId, @Param("limit") Integer limit, @Param("offset") Integer offset);
    int refreshPostCommentCount(@Param("postId") Long postId);
    PostReportRow selectPostReport(@Param("postId") Long postId, @Param("userId") Long userId);
    void insertPostReport(PostReportRow row);
}
