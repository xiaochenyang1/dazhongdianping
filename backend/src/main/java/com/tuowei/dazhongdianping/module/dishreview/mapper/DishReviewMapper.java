package com.tuowei.dazhongdianping.module.dishreview.mapper;

import com.tuowei.dazhongdianping.module.dishreview.model.DishReviewRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface DishReviewMapper {

    boolean existsDish(
            @Param("shopId") Long shopId,
            @Param("dishId") Long dishId,
            @Param("region") String region);

    void insert(DishReviewRow row);

    List<DishReviewRow> selectByDish(
            @Param("shopId") Long shopId,
            @Param("dishId") Long dishId,
            @Param("region") String region);
}
