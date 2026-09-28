package com.tuowei.dazhongdianping.module.consult.mapper;

import com.tuowei.dazhongdianping.module.consult.model.ConsultMessageRow;
import com.tuowei.dazhongdianping.module.consult.model.ConsultSessionRow;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ConsultMapper {

    Long selectShopMerchantId(@Param("shopId") Long shopId, @Param("region") String region);

    ConsultSessionRow selectSessionByUserShop(
            @Param("userId") Long userId, @Param("shopId") Long shopId, @Param("region") String region);

    void insertSession(ConsultSessionRow row);

    ConsultSessionRow selectUserSession(
            @Param("id") Long id, @Param("userId") Long userId, @Param("region") String region);

    ConsultSessionRow selectMerchantSession(
            @Param("id") Long id, @Param("merchantId") Long merchantId, @Param("region") String region);

    List<ConsultSessionRow> selectUserSessions(@Param("userId") Long userId, @Param("region") String region);

    List<ConsultSessionRow> selectMerchantSessions(
            @Param("merchantId") Long merchantId, @Param("region") String region);

    void insertMessage(ConsultMessageRow row);

    List<ConsultMessageRow> selectMessages(@Param("sessionId") Long sessionId);

    /** 发消息后刷新会话：写入最近消息并按发送方给对端未读 +1。 */
    int updateSessionOnMessage(
            @Param("id") Long id, @Param("content") String content, @Param("now") LocalDateTime now,
            @Param("userDelta") int userDelta, @Param("merchantDelta") int merchantDelta);

    int markUserRead(@Param("id") Long id);

    int markMerchantRead(@Param("id") Long id);
}
