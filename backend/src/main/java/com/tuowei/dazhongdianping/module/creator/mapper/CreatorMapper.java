package com.tuowei.dazhongdianping.module.creator.mapper;

import com.tuowei.dazhongdianping.module.creator.model.CreatorClaimRow;
import com.tuowei.dazhongdianping.module.creator.model.CreatorTaskRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface CreatorMapper {

    List<CreatorTaskRow> selectOpen(
            @Param("region") String region, @Param("userId") Long userId,
            @Param("limit") int limit, @Param("offset") int offset);

    long countOpen(@Param("region") String region);

    List<CreatorTaskRow> selectAdmin(
            @Param("region") String region, @Param("limit") int limit, @Param("offset") int offset);

    long countAdmin(@Param("region") String region);

    CreatorTaskRow selectTask(@Param("id") Long id, @Param("region") String region);

    CreatorClaimRow selectClaim(@Param("taskId") Long taskId, @Param("userId") Long userId);

    void insertClaim(CreatorClaimRow row);

    int completeClaim(@Param("id") Long id, @Param("userId") Long userId);

    int addUserPoints(@Param("userId") Long userId, @Param("points") int points);

    Integer selectUserPoints(@Param("userId") Long userId);

    void insertPointsLog(
            @Param("userId") Long userId, @Param("bizId") Long bizId,
            @Param("changeAmount") int changeAmount, @Param("balanceAfter") int balanceAfter,
            @Param("remark") String remark);

    void insertTask(CreatorTaskRow row);

    int updateTask(CreatorTaskRow row);
}
