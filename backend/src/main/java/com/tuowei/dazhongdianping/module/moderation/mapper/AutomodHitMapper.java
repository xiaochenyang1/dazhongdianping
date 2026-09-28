package com.tuowei.dazhongdianping.module.moderation.mapper;

import com.tuowei.dazhongdianping.module.moderation.model.AutomodHitRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AutomodHitMapper {

    void insert(AutomodHitRow row);

    long countHits(@Param("region") String region, @Param("decision") Integer decision);

    List<AutomodHitRow> selectHits(
            @Param("region") String region,
            @Param("decision") Integer decision,
            @Param("limit") int limit,
            @Param("offset") int offset);
}
