package com.tuowei.dazhongdianping.module.social.mapper;

import com.tuowei.dazhongdianping.module.social.model.SocialUserRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface SocialMapper {
    int countAvailableUser(@Param("userId") Long userId);
    String selectUserName(@Param("userId") Long userId);
    int countRelation(@Param("followerUserId") Long followerUserId, @Param("followedUserId") Long followedUserId);
    int insertRelation(@Param("followerUserId") Long followerUserId, @Param("followedUserId") Long followedUserId);
    int deleteRelation(@Param("followerUserId") Long followerUserId, @Param("followedUserId") Long followedUserId);
    long countFollowers(@Param("userId") Long userId);
    long countFollowing(@Param("userId") Long userId);
    List<SocialUserRow> selectFollowers(@Param("userId") Long userId, @Param("limit") int limit, @Param("offset") int offset);
    List<SocialUserRow> selectFollowing(@Param("userId") Long userId, @Param("limit") int limit, @Param("offset") int offset);
}
