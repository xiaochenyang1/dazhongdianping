package com.tuowei.dazhongdianping.module.merchant.verification.mapper;

import com.tuowei.dazhongdianping.module.merchant.verification.model.MerchantVerificationRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MerchantVerificationMapper {

    MerchantVerificationRow selectByMerchantId(@Param("merchantId") Long merchantId);

    MerchantVerificationRow selectByMerchantIdForUpdate(@Param("merchantId") Long merchantId);

    int insertVerification(MerchantVerificationRow row);

    int resubmitVerification(@Param("id") Long id,
                             @Param("merchantId") Long merchantId,
                             @Param("region") String region,
                             @Param("reason") String reason,
                             @Param("evidenceUrls") String evidenceUrls,
                             @Param("submittedBy") Long submittedBy);

    MerchantVerificationRow selectPendingVerificationForAudit(@Param("verificationId") Long verificationId,
                                                              @Param("region") String region);

    int approveVerification(@Param("id") Long id, @Param("auditBy") Long auditBy);

    int rejectVerification(@Param("id") Long id,
                           @Param("auditBy") Long auditBy,
                           @Param("rejectReason") String rejectReason);

    MerchantVerificationRow selectApprovedVerification(@Param("merchantId") Long merchantId,
                                                       @Param("region") String region);

    List<MerchantVerificationRow> selectApprovedVerifications(@Param("merchantIds") List<Long> merchantIds,
                                                              @Param("region") String region);
}
