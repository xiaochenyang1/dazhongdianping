package com.tuowei.dazhongdianping.module.admin.hotword.mapper;

import com.tuowei.dazhongdianping.module.admin.hotword.model.AdminHotWordRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AdminHotWordMapper {

    List<AdminHotWordRow> selectHotWords(@Param("region") String region);

    AdminHotWordRow selectHotWord(@Param("id") Long id, @Param("region") String region);

    Integer countKeywordConflict(@Param("region") String region,
                                 @Param("keyword") String keyword,
                                 @Param("excludeId") Long excludeId);

    int insertHotWord(AdminHotWordRow row);

    int updateHotWord(AdminHotWordRow row);

    int updateHotWordStatus(@Param("id") Long id,
                            @Param("region") String region,
                            @Param("enabled") boolean enabled);

    int deleteHotWord(@Param("id") Long id, @Param("region") String region);
}
