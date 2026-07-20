package com.tuowei.dazhongdianping.module.merchant.identity.mapper;

import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantOperatorRow;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantApplicationRow;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantRegistrationRow;
import com.tuowei.dazhongdianping.module.merchant.identity.model.MerchantRoleRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface MerchantIdentityMapper {

    MerchantOperatorRow selectOperatorByAccount(@Param("account") String account);

    MerchantOperatorRow selectOperatorById(@Param("operatorId") Long operatorId);

    MerchantOperatorRow selectMerchantOperator(@Param("operatorId") Long operatorId, @Param("merchantId") Long merchantId);

    void insertMerchant(MerchantRegistrationRow row);

    void insertOperator(MerchantOperatorRow row);

    void insertOperatorRole(@Param("operatorId") Long operatorId, @Param("roleId") Long roleId);

    void insertOperatorShop(@Param("operatorId") Long operatorId, @Param("shopId") Long shopId);

    List<MerchantRoleRow> selectAllRoles();

    List<MerchantRoleRow> selectRolesByIds(@Param("roleIds") List<Long> roleIds);

    List<MerchantRoleRow> selectOperatorRoles(@Param("operatorId") Long operatorId);

    List<Long> selectOperatorShopIds(@Param("operatorId") Long operatorId);

    long countOwnedShops(@Param("merchantId") Long merchantId, @Param("shopIds") List<Long> shopIds);

    int updateOperatorStatus(@Param("operatorId") Long operatorId, @Param("merchantId") Long merchantId, @Param("status") Integer status);

    long countMerchantStaff(@Param("merchantId") Long merchantId);

    List<MerchantOperatorRow> selectMerchantStaff(
            @Param("merchantId") Long merchantId,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    int updateOperatorProfile(
            @Param("operatorId") Long operatorId,
            @Param("merchantId") Long merchantId,
            @Param("name") String name,
            @Param("phone") String phone,
            @Param("email") String email,
            @Param("shopScopeType") Integer shopScopeType
    );

    void deleteOperatorRoles(@Param("operatorId") Long operatorId);

    void deleteOperatorShops(@Param("operatorId") Long operatorId);

    void insertOperationLog(@Param("merchantId") Long merchantId, @Param("operatorId") Long operatorId, @Param("action") String action, @Param("targetId") Long targetId);

    MerchantApplicationRow selectApplication(@Param("merchantId") Long merchantId);

    void insertApplication(
            @Param("merchantId") Long merchantId,
            @Param("licenseUrl") String licenseUrl,
            @Param("legalPerson") String legalPerson,
            @Param("shopPhotoUrls") String shopPhotoUrls
    );

    int updateApplication(
            @Param("merchantId") Long merchantId,
            @Param("licenseUrl") String licenseUrl,
            @Param("legalPerson") String legalPerson,
            @Param("shopPhotoUrls") String shopPhotoUrls
    );

    int updateMerchantAuditStatus(@Param("merchantId") Long merchantId, @Param("auditStatus") Integer auditStatus);

    long countApplications(@Param("region") String region, @Param("status") Integer status);

    List<MerchantApplicationRow> selectApplications(
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    MerchantApplicationRow selectAdminApplication(
            @Param("merchantId") Long merchantId,
            @Param("region") String region
    );

    int auditApplication(
            @Param("merchantId") Long merchantId,
            @Param("status") Integer status,
            @Param("reason") String reason,
            @Param("adminId") Long adminId
    );
}
