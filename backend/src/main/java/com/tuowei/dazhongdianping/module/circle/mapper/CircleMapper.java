package com.tuowei.dazhongdianping.module.circle.mapper;

import com.tuowei.dazhongdianping.module.circle.model.CircleMemberRow;
import com.tuowei.dazhongdianping.module.circle.model.CircleRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CircleMapper {
    long countCircles(@Param("region") String region, @Param("userId") Long userId, @Param("joinedOnly") boolean joinedOnly);
    List<CircleRow> listCircles(@Param("region") String region, @Param("userId") Long userId,
                                @Param("joinedOnly") boolean joinedOnly, @Param("limit") int limit, @Param("offset") int offset);
    CircleRow findAvailable(@Param("id") Long id, @Param("region") String region, @Param("userId") Long userId);
    long countMembers(@Param("circleId") Long circleId);
    List<CircleMemberRow> listMembers(@Param("circleId") Long circleId, @Param("limit") int limit, @Param("offset") int offset);
    int countMembership(@Param("circleId") Long circleId, @Param("userId") Long userId);
    int insertMembership(@Param("circleId") Long circleId, @Param("userId") Long userId);
    int deleteMembership(@Param("circleId") Long circleId, @Param("userId") Long userId);
    int incrementMembers(@Param("circleId") Long circleId);
    int decrementMembers(@Param("circleId") Long circleId);
    int currentMemberCount(@Param("circleId") Long circleId);
    int refreshPostCountByPostId(@Param("postId") Long postId);
    long countAdminCircles(@Param("region") String region, @Param("status") Integer status, @Param("keyword") String keyword);
    List<CircleRow> listAdminCircles(@Param("region") String region, @Param("status") Integer status, @Param("keyword") String keyword,
                                     @Param("limit") int limit, @Param("offset") int offset);
    CircleRow findAdminCircle(@Param("id") Long id, @Param("region") String region);
    int countNameConflict(@Param("region") String region, @Param("name") String name, @Param("excludeId") Long excludeId);
    int insertCircle(CircleRow row);
    int updateCircle(CircleRow row);
    int updateCircleStatus(@Param("id") Long id, @Param("region") String region, @Param("status") Integer status);
}
