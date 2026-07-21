package com.tuowei.dazhongdianping.module.admin.activity.mapper;

import com.tuowei.dazhongdianping.module.admin.activity.model.AdminOperationActivityItemRow;
import com.tuowei.dazhongdianping.module.admin.activity.model.AdminOperationActivityRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AdminOperationActivityMapper {

    List<AdminOperationActivityRow> selectActivities(@Param("region") String region,
                                                     @Param("cityId") Long cityId,
                                                     @Param("status") Integer status);

    AdminOperationActivityRow selectActivity(@Param("id") Long id, @Param("region") String region);

    Integer countActiveCity(@Param("cityId") Long cityId, @Param("region") String region);

    Integer countActivityCodeConflict(@Param("code") String code, @Param("excludeId") Long excludeId);

    int insertActivity(AdminOperationActivityRow row);

    int updateActivity(AdminOperationActivityRow row);

    int updateActivityStatus(@Param("id") Long id,
                             @Param("region") String region,
                             @Param("status") Integer status,
                             @Param("updatedBy") Long updatedBy);

    int deleteActivity(@Param("id") Long id, @Param("region") String region);

    int deleteItemsByActivity(@Param("activityId") Long activityId);

    List<AdminOperationActivityItemRow> selectItems(@Param("activityId") Long activityId,
                                                    @Param("region") String region);

    AdminOperationActivityItemRow selectItem(@Param("activityId") Long activityId,
                                             @Param("id") Long id,
                                             @Param("region") String region);

    Integer countActivityItemConflict(@Param("activityId") Long activityId,
                                      @Param("targetType") Integer targetType,
                                      @Param("targetId") Long targetId,
                                      @Param("excludeId") Long excludeId);

    int insertItem(AdminOperationActivityItemRow row);

    int updateItem(AdminOperationActivityItemRow row);

    int updateItemStatus(@Param("activityId") Long activityId,
                         @Param("id") Long id,
                         @Param("region") String region,
                         @Param("status") Integer status);

    int deleteItem(@Param("activityId") Long activityId,
                   @Param("id") Long id,
                   @Param("region") String region);

    Integer countAvailableShop(@Param("targetId") Long targetId, @Param("region") String region);

    Integer countAvailableDeal(@Param("targetId") Long targetId, @Param("region") String region);

    Integer countAvailablePost(@Param("targetId") Long targetId, @Param("region") String region);

    Integer countAvailableRank(@Param("targetId") Long targetId, @Param("region") String region);

    Integer countAvailableTopic(@Param("targetId") Long targetId, @Param("region") String region);
}
