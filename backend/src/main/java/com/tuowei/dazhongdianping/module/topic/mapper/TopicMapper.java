package com.tuowei.dazhongdianping.module.topic.mapper;

import com.tuowei.dazhongdianping.module.topic.model.TopicHotMetricRow;
import com.tuowei.dazhongdianping.module.topic.model.TopicHotSnapshotRow;
import com.tuowei.dazhongdianping.module.topic.model.TopicRow;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface TopicMapper {
    long countPublicTopics(@Param("region") String region, @Param("sort") String sort);

    List<TopicRow> listPublicTopics(@Param("region") String region,
                                    @Param("userId") Long userId,
                                    @Param("sort") String sort,
                                    @Param("limit") int limit,
                                    @Param("offset") int offset);

    long countFollowingTopics(@Param("region") String region, @Param("userId") Long userId);

    List<TopicRow> listFollowingTopics(@Param("region") String region,
                                       @Param("userId") Long userId,
                                       @Param("limit") int limit,
                                       @Param("offset") int offset);

    TopicRow findAvailable(@Param("id") Long id, @Param("region") String region, @Param("userId") Long userId);

    TopicRow selectByNameAnyStatus(@Param("region") String region, @Param("name") String name);

    TopicRow selectByIdAnyStatus(@Param("id") Long id, @Param("region") String region);

    int insertTopic(TopicRow row);

    int countFollow(@Param("topicId") Long topicId, @Param("userId") Long userId);

    int insertFollow(@Param("topicId") Long topicId, @Param("userId") Long userId);

    int deleteFollow(@Param("topicId") Long topicId, @Param("userId") Long userId);

    int refreshFollowerCount(@Param("topicId") Long topicId);

    int currentFollowerCount(@Param("topicId") Long topicId);

    List<Long> selectPostTopicIds(@Param("postId") Long postId);

    int refreshPostCounts(@Param("topicIds") List<Long> topicIds);

    int touchTopicsByPostId(@Param("postId") Long postId);

    List<Long> selectPublicTopicIds(@Param("region") String region);

    List<Long> selectDirtyPublicTopicIds(@Param("region") String region);

    List<TopicHotMetricRow> selectHotMetrics(@Param("region") String region,
                                             @Param("cutoff") LocalDateTime cutoff,
                                             @Param("topicIds") List<Long> topicIds);

    int deleteHotSnapshots(@Param("topicIds") List<Long> topicIds);

    int deleteInvalidHotSnapshots(@Param("region") String region);

    int insertHotSnapshot(TopicHotSnapshotRow row);

    int countRegionHotSnapshots(@Param("region") String region);

    long countAdminTopics(@Param("region") String region,
                          @Param("status") Integer status,
                          @Param("recommended") Boolean recommended,
                          @Param("keyword") String keyword);

    List<TopicRow> listAdminTopics(@Param("region") String region,
                                   @Param("status") Integer status,
                                   @Param("recommended") Boolean recommended,
                                   @Param("keyword") String keyword,
                                   @Param("limit") int limit,
                                   @Param("offset") int offset);

    TopicRow findAdminTopic(@Param("id") Long id, @Param("region") String region);

    TopicRow findAdminTopicForUpdate(@Param("id") Long id, @Param("region") String region);

    TopicRow findAnyTopicForUpdate(@Param("id") Long id);

    int countTopicNameConflict(@Param("region") String region,
                               @Param("name") String name,
                               @Param("excludeId") Long excludeId);

    int updateTopicName(@Param("id") Long id, @Param("region") String region, @Param("name") String name);

    int updateTopicRecommendation(@Param("id") Long id, @Param("region") String region,
                                  @Param("recommended") boolean recommended,
                                  @Param("pinnedSort") Integer pinnedSort);

    int updateTopicStatus(@Param("id") Long id, @Param("region") String region, @Param("status") Integer status);

    int deleteHotSnapshot(@Param("topicId") Long topicId);

    List<Long> selectPostIdsByTopic(@Param("topicId") Long topicId);

    int countPostTopic(@Param("topicId") Long topicId, @Param("postId") Long postId);

    int deletePostTopic(@Param("topicId") Long topicId, @Param("postId") Long postId);

    int movePostTopic(@Param("sourceId") Long sourceId, @Param("targetId") Long targetId,
                      @Param("postId") Long postId);

    List<Long> selectFollowerUserIds(@Param("topicId") Long topicId);

    int countTopicFollow(@Param("topicId") Long topicId, @Param("userId") Long userId);

    int deleteTopicFollow(@Param("topicId") Long topicId, @Param("userId") Long userId);

    int moveTopicFollow(@Param("sourceId") Long sourceId, @Param("targetId") Long targetId,
                        @Param("userId") Long userId);

    int markTopicMerged(@Param("sourceId") Long sourceId, @Param("region") String region,
                        @Param("targetId") Long targetId);
}
