package com.tuowei.dazhongdianping.module.invoice.mapper;

import com.tuowei.dazhongdianping.module.invoice.model.InvoiceOrderRow;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceRequestRow;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceTitleRow;
import com.tuowei.dazhongdianping.module.invoice.model.TaxRateRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface InvoiceMapper {

    List<InvoiceTitleRow> selectTitles(@Param("userId") Long userId, @Param("region") String region);

    InvoiceTitleRow selectTitle(
            @Param("id") Long id, @Param("userId") Long userId, @Param("region") String region);

    void clearDefaultTitles(@Param("userId") Long userId, @Param("region") String region);

    void insertTitle(InvoiceTitleRow row);

    InvoiceOrderRow selectOrder(@Param("id") Long id);

    int countByOrder(@Param("orderId") Long orderId);

    TaxRateRow selectEnabledTaxRate(@Param("region") String region);

    void insertRequest(InvoiceRequestRow row);

    List<InvoiceRequestRow> selectUserRequests(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("limit") int limit,
            @Param("offset") int offset);

    long countUserRequests(@Param("userId") Long userId, @Param("region") String region);

    InvoiceRequestRow selectRequest(@Param("id") Long id, @Param("region") String region);

    List<InvoiceRequestRow> selectAdminRequests(
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("limit") int limit,
            @Param("offset") int offset);

    long countAdminRequests(@Param("region") String region, @Param("status") Integer status);

    int issue(
            @Param("id") Long id, @Param("region") String region, @Param("invoiceNo") String invoiceNo);

    int reject(
            @Param("id") Long id, @Param("region") String region, @Param("reason") String reason);

    List<TaxRateRow> selectTaxRates(@Param("region") String region);

    TaxRateRow selectTaxRate(@Param("id") Long id, @Param("region") String region);

    int updateTaxRate(TaxRateRow row);
}
