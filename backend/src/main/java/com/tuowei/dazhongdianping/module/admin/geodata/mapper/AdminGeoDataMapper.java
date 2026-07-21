package com.tuowei.dazhongdianping.module.admin.geodata.mapper;

import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminAreaRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminCategoryRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminCityRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AdminGeoDataMapper {

    List<AdminCategoryRow> selectCategories(@Param("region") String region);

    AdminCategoryRow selectCategory(@Param("region") String region, @Param("id") Long id);

    AdminCategoryRow selectCategoryForUpdate(@Param("region") String region, @Param("id") Long id);

    int countCategoryNameConflict(@Param("region") String region,
                                  @Param("parentId") Long parentId,
                                  @Param("name") String name,
                                  @Param("excludeId") Long excludeId);

    void insertCategory(AdminCategoryRow row);

    int updateCategory(AdminCategoryRow row);

    int updateCategoryStatus(@Param("region") String region,
                             @Param("id") Long id,
                             @Param("status") Integer status);

    List<Long> selectShopIdsByCategory(@Param("region") String region,
                                       @Param("categoryId") Long categoryId);

    int deleteCategory(@Param("region") String region, @Param("id") Long id);

    int countEnabledCategoryChildren(@Param("region") String region,
                                     @Param("parentId") Long parentId);

    int countAnyCategoryChildren(@Param("region") String region,
                                 @Param("parentId") Long parentId);

    int countCategoryBusinessReferences(@Param("region") String region,
                                        @Param("categoryId") Long categoryId);

    List<AdminCityRow> selectCities(@Param("region") String region);

    AdminCityRow selectCity(@Param("region") String region, @Param("id") Long id);

    AdminCityRow selectCityForUpdate(@Param("region") String region, @Param("id") Long id);

    int countCityCodeConflict(@Param("region") String region,
                              @Param("code") String code,
                              @Param("excludeId") Long excludeId);

    int countCityNameConflict(@Param("region") String region,
                              @Param("name") String name,
                              @Param("excludeId") Long excludeId);

    void insertCity(AdminCityRow row);

    int updateCity(AdminCityRow row);

    int updateCityStatus(@Param("region") String region,
                         @Param("id") Long id,
                         @Param("status") Integer status);

    List<Long> selectShopIdsByCity(@Param("region") String region,
                                   @Param("cityId") Long cityId);

    int deleteCity(@Param("region") String region, @Param("id") Long id);

    int countAreasByCity(@Param("region") String region, @Param("cityId") Long cityId);

    int countCityBusinessReferences(@Param("region") String region,
                                    @Param("cityId") Long cityId);

    List<AdminAreaRow> selectAreas(@Param("region") String region,
                                   @Param("cityId") Long cityId);

    AdminAreaRow selectArea(@Param("region") String region, @Param("id") Long id);

    AdminAreaRow selectAreaForUpdate(@Param("region") String region, @Param("id") Long id);

    int countAreaNameConflict(@Param("region") String region,
                              @Param("cityId") Long cityId,
                              @Param("name") String name,
                              @Param("excludeId") Long excludeId);

    void insertArea(AdminAreaRow row);

    int updateArea(AdminAreaRow row);

    int updateAreaStatus(@Param("region") String region,
                         @Param("id") Long id,
                         @Param("status") Integer status);

    List<Long> selectShopIdsByArea(@Param("region") String region,
                                   @Param("areaId") Long areaId);

    int deleteArea(@Param("region") String region, @Param("id") Long id);

    int countAreaReferences(@Param("region") String region, @Param("areaId") Long areaId);

    Long selectShopAreaReferenceForUpdate(@Param("region") String region, @Param("areaId") Long areaId);

    Long selectShopChangeAreaReferenceForUpdate(@Param("region") String region, @Param("areaId") Long areaId);
}
