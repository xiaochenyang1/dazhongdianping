package com.tuowei.dazhongdianping.module.moderation.mapper;

import com.tuowei.dazhongdianping.module.moderation.model.SensitiveWordRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface SensitiveWordMapper {

    List<SensitiveWordRow> selectWords(@Param("region") String region);

    List<String> selectEnabledWords(@Param("region") String region);

    SensitiveWordRow selectWord(@Param("id") Long id, @Param("region") String region);

    Integer countWordConflict(
            @Param("region") String region,
            @Param("word") String word,
            @Param("excludeId") Long excludeId
    );

    int insertWord(SensitiveWordRow row);

    int updateWord(SensitiveWordRow row);

    int updateWordStatus(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("enabled") boolean enabled
    );

    int deleteWord(@Param("id") Long id, @Param("region") String region);
}
