package com.tuowei.dazhongdianping.module.ticket.mapper;

import com.tuowei.dazhongdianping.module.ticket.model.SupportTicketRow;
import com.tuowei.dazhongdianping.module.ticket.model.TicketMessageRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface TicketMapper {

    Long selectShopMerchantId(@Param("shopId") Long shopId, @Param("region") String region);

    int countShop(@Param("shopId") Long shopId, @Param("region") String region);

    void insertTicket(SupportTicketRow row);

    void insertMessage(TicketMessageRow row);

    void touch(@Param("id") Long id, @Param("region") String region);

    int updateStatus(@Param("id") Long id, @Param("region") String region, @Param("status") int status);

    SupportTicketRow selectOwned(
            @Param("id") Long id, @Param("region") String region,
            @Param("requesterType") int requesterType, @Param("requesterId") long requesterId);

    SupportTicketRow selectById(@Param("id") Long id, @Param("region") String region);

    List<SupportTicketRow> selectOwnedTickets(
            @Param("region") String region, @Param("requesterType") int requesterType,
            @Param("requesterId") long requesterId, @Param("limit") int limit, @Param("offset") int offset);

    long countOwnedTickets(
            @Param("region") String region, @Param("requesterType") int requesterType,
            @Param("requesterId") long requesterId);

    List<SupportTicketRow> selectAdminTickets(
            @Param("region") String region, @Param("status") Integer status,
            @Param("limit") int limit, @Param("offset") int offset);

    long countAdminTickets(@Param("region") String region, @Param("status") Integer status);

    List<TicketMessageRow> selectMessages(@Param("ticketId") Long ticketId);
}
