package com.tuowei.dazhongdianping.module.activity.mapper;

import com.tuowei.dazhongdianping.module.activity.model.PublicActivityItemRow;
import com.tuowei.dazhongdianping.module.activity.model.PublicActivityRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface PublicActivityMapper {

    List<PublicActivityRow> selectOnlineActivities(@Param("region") String region,
                                                   @Param("cityId") Long cityId,
                                                   @Param("channel") Integer channel,
                                                   @Param("limit") Integer limit);

    PublicActivityRow selectOnlineActivity(@Param("id") Long id, @Param("region") String region);

    List<PublicActivityItemRow> selectEnabledItems(@Param("activityId") Long activityId,
                                                   @Param("region") String region);
}
