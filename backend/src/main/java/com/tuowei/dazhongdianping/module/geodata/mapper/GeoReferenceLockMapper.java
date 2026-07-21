package com.tuowei.dazhongdianping.module.geodata.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface GeoReferenceLockMapper {

    Long lockActiveCategory(@Param("region") String region, @Param("categoryId") Long categoryId);

    Long lockActiveCity(@Param("region") String region, @Param("cityId") Long cityId);

    Long lockActiveArea(@Param("region") String region,
                        @Param("cityId") Long cityId,
                        @Param("areaId") Long areaId);

    List<Long> lockCategories(@Param("region") String region, @Param("ids") List<Long> ids);

    List<Long> lockCities(@Param("region") String region, @Param("ids") List<Long> ids);

    List<Long> lockAreas(@Param("region") String region, @Param("ids") List<Long> ids);
}
