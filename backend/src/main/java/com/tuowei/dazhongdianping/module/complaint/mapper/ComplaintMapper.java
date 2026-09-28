package com.tuowei.dazhongdianping.module.complaint.mapper;

import com.tuowei.dazhongdianping.module.complaint.model.ComplaintLogRow;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintTicketRow;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ComplaintMapper {

    /** 校验门店并取其商户 id（用于把投诉派发给对应商家）；不存在返回 null。 */
    Long selectShopMerchantId(@Param("shopId") Long shopId, @Param("region") String region);

    void insertTicket(ComplaintTicketRow row);

    void insertLog(ComplaintLogRow row);

    ComplaintTicketRow selectTicket(@Param("id") Long id, @Param("region") String region);

    ComplaintTicketRow selectUserTicket(
            @Param("id") Long id, @Param("userId") Long userId, @Param("region") String region);

    ComplaintTicketRow selectMerchantTicket(
            @Param("id") Long id, @Param("merchantId") Long merchantId, @Param("region") String region);

    List<ComplaintTicketRow> selectUserTickets(
            @Param("userId") Long userId, @Param("region") String region,
            @Param("status") Integer status, @Param("limit") int limit, @Param("offset") int offset);

    long countUserTickets(
            @Param("userId") Long userId, @Param("region") String region, @Param("status") Integer status);

    List<ComplaintTicketRow> selectMerchantTickets(
            @Param("merchantId") Long merchantId, @Param("region") String region,
            @Param("status") Integer status, @Param("limit") int limit, @Param("offset") int offset);

    long countMerchantTickets(
            @Param("merchantId") Long merchantId, @Param("region") String region, @Param("status") Integer status);

    List<ComplaintTicketRow> selectAdminTickets(
            @Param("region") String region, @Param("status") Integer status,
            @Param("limit") int limit, @Param("offset") int offset);

    long countAdminTickets(@Param("region") String region, @Param("status") Integer status);

    List<ComplaintLogRow> selectLogs(@Param("ticketId") Long ticketId);

    /** 商家申辩：仅当状态为待受理/处理中时写入回复并置为处理中，返回受影响行数。 */
    int updateMerchantReply(
            @Param("id") Long id, @Param("merchantId") Long merchantId,
            @Param("reply") String reply, @Param("now") LocalDateTime now);

    /** 平台仲裁：仅当状态为待受理/处理中时置为已解决/已驳回，返回受影响行数。 */
    int updateResolution(
            @Param("id") Long id, @Param("region") String region, @Param("status") Integer status,
            @Param("resolution") String resolution, @Param("resolvedBy") Long resolvedBy,
            @Param("now") LocalDateTime now);
}
