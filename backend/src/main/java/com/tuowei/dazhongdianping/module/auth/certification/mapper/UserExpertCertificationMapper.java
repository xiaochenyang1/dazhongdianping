package com.tuowei.dazhongdianping.module.auth.certification.mapper;

import com.tuowei.dazhongdianping.module.auth.certification.model.UserExpertCertificationRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface UserExpertCertificationMapper {

    UserExpertCertificationRow selectByUserAndRegion(@Param("userId") Long userId,
                                                     @Param("region") String region);

    UserExpertCertificationRow selectByUserAndRegionForUpdate(@Param("userId") Long userId,
                                                              @Param("region") String region);

    void insertCertification(UserExpertCertificationRow row);

    int resubmitCertification(@Param("id") Long id,
                              @Param("userId") Long userId,
                              @Param("region") String region,
                              @Param("reason") String reason);

    UserExpertCertificationRow selectPendingCertificationForAudit(@Param("certificationId") Long certificationId,
                                                                  @Param("region") String region);

    int approveCertification(@Param("id") Long id,
                             @Param("auditBy") Long auditBy);

    int rejectCertification(@Param("id") Long id,
                            @Param("auditBy") Long auditBy,
                            @Param("rejectReason") String rejectReason);

    UserExpertCertificationRow selectApprovedCertification(@Param("userId") Long userId,
                                                           @Param("region") String region);

    List<UserExpertCertificationRow> selectApprovedCertifications(@Param("userIds") List<Long> userIds,
                                                                  @Param("region") String region);
}
