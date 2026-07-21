package com.tuowei.dazhongdianping.module.message.mapper;

import com.tuowei.dazhongdianping.module.message.model.BlockedUserRow;
import com.tuowei.dazhongdianping.module.message.model.ConversationRow;
import com.tuowei.dazhongdianping.module.message.model.MessageRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MessageMapper {
    int countAvailableUser(@Param("userId") Long userId);
    String selectUserName(@Param("userId") Long userId);
    Long findConversation(@Param("userA") Long userA, @Param("userB") Long userB);
    int insertConversation(@Param("userA") Long userA, @Param("userB") Long userB);
    Long lastInsertedId();
    int countConversationMember(@Param("conversationId") Long conversationId, @Param("userId") Long userId);
    int countBlockEitherDirection(@Param("firstUserId") Long firstUserId, @Param("secondUserId") Long secondUserId);
    int insertMessage(MessageRow row);
    int updateConversation(@Param("conversationId") Long conversationId, @Param("messageId") Long messageId,
                           @Param("preview") String preview);
    long countConversations(@Param("userId") Long userId);
    List<ConversationRow> listConversations(@Param("userId") Long userId, @Param("limit") int limit, @Param("offset") int offset);
    long countMessages(@Param("conversationId") Long conversationId);
    List<MessageRow> listMessages(@Param("conversationId") Long conversationId, @Param("limit") int limit, @Param("offset") int offset);
    int markRead(@Param("conversationId") Long conversationId, @Param("userId") Long userId);
    int insertBlock(@Param("userId") Long userId, @Param("blockedUserId") Long blockedUserId);
    int deleteBlock(@Param("userId") Long userId, @Param("blockedUserId") Long blockedUserId);
    long countBlocks(@Param("userId") Long userId);
    List<BlockedUserRow> listBlocks(@Param("userId") Long userId, @Param("limit") int limit, @Param("offset") int offset);
    int countReport(@Param("reporterUserId") Long reporterUserId, @Param("targetType") Integer targetType, @Param("targetId") Long targetId);
    int countReportableTarget(@Param("reporterUserId") Long reporterUserId, @Param("targetType") Integer targetType, @Param("targetId") Long targetId);
    int insertReport(@Param("reporterUserId") Long reporterUserId, @Param("targetType") Integer targetType,
                     @Param("targetId") Long targetId, @Param("reason") String reason);
}
