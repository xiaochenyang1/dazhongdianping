package com.tuowei.dazhongdianping.module.auth.mapper;

import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.auth.model.GrowthPointsLogRow;
import com.tuowei.dazhongdianping.module.auth.model.GrowthRuleRow;
import com.tuowei.dazhongdianping.module.auth.model.UserGrowthRecordQuery;
import com.tuowei.dazhongdianping.module.auth.model.UserSessionRow;
import com.tuowei.dazhongdianping.module.auth.model.VerificationCodeRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AuthCommandMapper {

    void insertVerificationCode(VerificationCodeRow row);

    VerificationCodeRow selectLatestVerificationCode(@Param("scene") String scene,
                                                     @Param("targetType") Integer targetType,
                                                     @Param("target") String target);

    int markVerificationCodeUsed(@Param("id") Long id);

    AppUserRow selectUserByEmail(@Param("email") String email);

    AppUserRow selectUserByPhone(@Param("phone") String phone);

    AppUserRow selectUserById(@Param("userId") Long userId);

    AppUserRow selectUserByIdForUpdate(@Param("userId") Long userId);

    void insertUser(AppUserRow row);

    int updateUserLastLogin(@Param("userId") Long userId);

    int updateUserPassword(@Param("userId") Long userId, @Param("passwordHash") String passwordHash);

    int updateUserProfile(AppUserRow row);

    int updateUserEmail(@Param("userId") Long userId, @Param("email") String email);

    int updateUserPhone(@Param("userId") Long userId, @Param("phone") String phone);

    int updateUserGrowthProfile(@Param("userId") Long userId,
                                @Param("growthValue") Integer growthValue,
                                @Param("level") Integer level,
                                @Param("points") Integer points);

    long countPublicReviewsByUserId(@Param("userId") Long userId, @Param("region") String region);

    void insertGrowthPointsLog(GrowthPointsLogRow row);

    long countGrowthPointsLogs(UserGrowthRecordQuery query);

    List<GrowthPointsLogRow> selectGrowthPointsLogs(UserGrowthRecordQuery query);

    long countGrowthPointsLogsByAction(@Param("userId") Long userId,
                                       @Param("action") String action,
                                       @Param("type") Integer type,
                                       @Param("bizId") Long bizId);

    GrowthRuleRow selectEnabledGrowthRule(@Param("action") String action);

    long countDailyGrowthActions(@Param("userId") Long userId, @Param("action") String action);

    Integer selectLevelByGrowth(@Param("growthValue") Integer growthValue);

    void insertUserSession(UserSessionRow row);

    UserSessionRow selectUserSessionById(@Param("sessionId") Long sessionId);

    UserSessionRow selectUserSessionByRefreshTokenHash(@Param("refreshTokenHash") String refreshTokenHash);

    int updateUserSessionRefreshToken(UserSessionRow row);

    int revokeUserSession(@Param("sessionId") Long sessionId);

    int revokeUserSessionsByUserId(@Param("userId") Long userId);
}
