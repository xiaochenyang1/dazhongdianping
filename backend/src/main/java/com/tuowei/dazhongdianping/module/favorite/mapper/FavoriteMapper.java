package com.tuowei.dazhongdianping.module.favorite.mapper;

import com.tuowei.dazhongdianping.module.favorite.model.FavoriteQuery;
import com.tuowei.dazhongdianping.module.favorite.model.FavoriteRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface FavoriteMapper {
    FavoriteRow selectShopTarget(@Param("targetId") Long targetId, @Param("region") String region);
    FavoriteRow selectPostTarget(@Param("targetId") Long targetId, @Param("region") String region);
    FavoriteRow selectFavorite(@Param("userId") Long userId, @Param("targetType") Integer targetType, @Param("targetId") Long targetId, @Param("region") String region);
    void insertFavorite(FavoriteRow row);
    int deleteFavorite(@Param("userId") Long userId, @Param("targetType") Integer targetType, @Param("targetId") Long targetId);
    long countFavorites(FavoriteQuery query);
    List<FavoriteRow> selectFavorites(FavoriteQuery query);
}
