package com.tuowei.dazhongdianping.common.messaging;

/** 进程内消息发布。实现只写 message_outbox，不连接外部 broker。 */
public interface MessagePublisher {

    /**
     * 写入一条已发布的 outbox 记录。
     *
     * @return message_outbox.id
     */
    long publish(String topic, String payload);
}
