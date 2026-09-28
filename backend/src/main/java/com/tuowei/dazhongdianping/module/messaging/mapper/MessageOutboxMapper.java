package com.tuowei.dazhongdianping.module.messaging.mapper;

import com.tuowei.dazhongdianping.module.messaging.model.MessageOutboxRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MessageOutboxMapper {

    void insert(MessageOutboxRow row);

    MessageOutboxRow selectById(@Param("id") Long id);
}
