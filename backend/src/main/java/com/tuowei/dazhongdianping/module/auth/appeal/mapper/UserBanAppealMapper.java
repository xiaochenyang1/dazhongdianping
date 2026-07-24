package com.tuowei.dazhongdianping.module.auth.appeal.mapper;

import com.tuowei.dazhongdianping.module.auth.appeal.model.UserBanAppealRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface UserBanAppealMapper {

    void insertAppeal(UserBanAppealRow row);

    UserBanAppealRow selectPendingAppealByUserIdForUpdate(@Param("userId") Long userId);

    List<UserBanAppealRow> selectPendingAppealsByUserId(@Param("userId") Long userId);

    UserBanAppealRow selectPendingAppealForAudit(@Param("appealId") Long appealId,
                                                 @Param("region") String region);

    UserBanAppealRow selectAppealById(@Param("appealId") Long appealId);

    UserBanAppealRow selectLatestAppealByUserId(@Param("userId") Long userId);

    long countPendingAppealsByUserId(@Param("userId") Long userId);

    int resolveAppeal(@Param("appealId") Long appealId,
                      @Param("status") Integer status,
                      @Param("auditBy") Long auditBy,
                      @Param("rejectReason") String rejectReason);
}
