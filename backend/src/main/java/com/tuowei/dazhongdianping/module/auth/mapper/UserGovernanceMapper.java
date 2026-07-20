package com.tuowei.dazhongdianping.module.auth.mapper;

import com.tuowei.dazhongdianping.module.auth.model.UserDeviceRow;
import com.tuowei.dazhongdianping.module.auth.model.UserPolicyAcceptLogRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface UserGovernanceMapper {
    void insertPolicyAcceptLog(UserPolicyAcceptLogRow row);

    List<UserPolicyAcceptLogRow> selectPolicyAcceptLogsByUserId(@Param("userId") Long userId);

    UserDeviceRow selectDeviceByUidForUpdate(@Param("deviceUid") String deviceUid);

    UserDeviceRow selectDeviceByIdAndUserId(@Param("deviceId") Long deviceId, @Param("userId") Long userId);

    List<UserDeviceRow> selectDevicesByUserId(@Param("userId") Long userId);

    void insertDevice(UserDeviceRow row);

    int updateDeviceRegistration(UserDeviceRow row);

    int updateDevicePushToken(UserDeviceRow row);

    int logoutDevice(@Param("deviceId") Long deviceId, @Param("userId") Long userId);
}
