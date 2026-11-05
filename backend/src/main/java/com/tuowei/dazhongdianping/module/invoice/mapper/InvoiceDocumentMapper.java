package com.tuowei.dazhongdianping.module.invoice.mapper;

import com.tuowei.dazhongdianping.module.invoice.model.InvoiceDocumentRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface InvoiceDocumentMapper {
    InvoiceDocumentRow selectDocument(@Param("invoiceId") Long invoiceId);
    List<InvoiceDocumentRow> selectUserMetadata(@Param("userId") Long userId);
    void insertDocument(InvoiceDocumentRow row);
    int confirmReceipt(@Param("invoiceId") Long invoiceId, @Param("sha256") String sha256);
    int deleteUserDocuments(@Param("userId") Long userId);
}
