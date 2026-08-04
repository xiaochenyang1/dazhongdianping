package com.tuowei.dazhongdianping.module.points.mapper;

import com.tuowei.dazhongdianping.module.points.model.PointsExchangeRow;
import com.tuowei.dazhongdianping.module.points.model.PointsProductRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface PointsMapper {

    long countOnlineProducts(@Param("region") String region);

    List<PointsProductRow> selectOnlineProducts(@Param("region") String region,
                                                @Param("limit") Integer limit,
                                                @Param("offset") Integer offset);

    PointsProductRow selectOnlineProductById(@Param("id") Long id, @Param("region") String region);

    PointsProductRow selectProductByIdForUpdate(@Param("id") Long id, @Param("region") String region);

    int decrementProductStock(@Param("id") Long id, @Param("region") String region);

    int restoreProductStock(@Param("id") Long id);

    long countUserExchanges(@Param("userId") Long userId, @Param("productId") Long productId);

    void insertExchange(PointsExchangeRow row);

    long countUserExchangesAll(@Param("userId") Long userId);

    List<PointsExchangeRow> selectUserExchanges(@Param("userId") Long userId,
                                                @Param("limit") Integer limit,
                                                @Param("offset") Integer offset);

    PointsExchangeRow selectExchangeById(@Param("id") Long id, @Param("region") String region);

    long countExchanges(@Param("region") String region,
                        @Param("status") Integer status,
                        @Param("keyword") String keyword);

    List<PointsExchangeRow> selectExchanges(@Param("region") String region,
                                            @Param("status") Integer status,
                                            @Param("keyword") String keyword,
                                            @Param("limit") Integer limit,
                                            @Param("offset") Integer offset);

    int markExchangeFulfilled(@Param("id") Long id,
                              @Param("redeemCode") String redeemCode,
                              @Param("remark") String remark);

    int markExchangeCancelled(@Param("id") Long id, @Param("remark") String remark);

    List<PointsExchangeRow> selectExchangesForExport(@Param("userId") Long userId);

    long countProductsByRegion(@Param("region") String region);

    List<PointsProductRow> selectProductsByRegion(@Param("region") String region,
                                                  @Param("limit") Integer limit,
                                                  @Param("offset") Integer offset);

    PointsProductRow selectProductById(@Param("id") Long id, @Param("region") String region);

    int insertProduct(PointsProductRow row);

    int updateProduct(PointsProductRow row);

    int updateProductStatus(@Param("id") Long id,
                            @Param("region") String region,
                            @Param("status") Integer status);

    int softDeleteProduct(@Param("id") Long id, @Param("region") String region);
}
