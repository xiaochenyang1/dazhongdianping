package com.tuowei.dazhongdianping.module.admin.banner.mapper;

import com.tuowei.dazhongdianping.module.admin.banner.model.AdminBannerRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AdminBannerMapper {

    List<AdminBannerRow> selectBanners(@Param("region") String region, @Param("cityId") Long cityId);

    AdminBannerRow selectBanner(@Param("id") Long id, @Param("region") String region);

    Long selectNextBannerId();

    Integer countActiveCity(@Param("cityId") Long cityId, @Param("region") String region);

    int insertBanner(AdminBannerRow row);

    int updateBanner(AdminBannerRow row);

    int updateBannerStatus(@Param("id") Long id,
                           @Param("region") String region,
                           @Param("enabled") boolean enabled);

    int deleteBanner(@Param("id") Long id, @Param("region") String region);
}
