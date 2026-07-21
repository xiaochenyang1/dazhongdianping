package com.tuowei.dazhongdianping.module.notification.mapper;

import com.tuowei.dazhongdianping.module.notification.model.NotificationRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface NotificationMapper {
    long count(@Param("userId") Long userId, @Param("region") String region);
    List<NotificationRow> list(@Param("userId") Long userId, @Param("region") String region,
                               @Param("offset") int offset, @Param("pageSize") int pageSize);
    long countUnread(@Param("userId") Long userId, @Param("region") String region);
    NotificationRow findLatestUnreadForAggregate(@Param("userId") Long userId, @Param("region") String region,
                                                 @Param("type") String type, @Param("linkUrl") String linkUrl);
    NotificationRow findOwned(@Param("id") Long id, @Param("userId") Long userId, @Param("region") String region);
    int bumpAggregate(@Param("id") Long id, @Param("actorUserId") Long actorUserId, @Param("title") String title,
                      @Param("content") String content, @Param("linkUrl") String linkUrl);
    int markRead(@Param("id") Long id, @Param("userId") Long userId, @Param("region") String region);
    int insert(NotificationRow row);
}
