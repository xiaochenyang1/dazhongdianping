package com.tuowei.dazhongdianping.module.messaging.service;

import com.tuowei.dazhongdianping.common.messaging.MessagePublisher;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.messaging.mapper.MessageOutboxMapper;
import com.tuowei.dazhongdianping.module.messaging.model.MessageOutboxRow;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 唯一的消息发布实现：把消息落进 message_outbox，状态直接记为已发布。 */
@Service
public class InProcessMessagePublisher implements MessagePublisher {

    private final MessageOutboxMapper mapper;

    public InProcessMessagePublisher(MessageOutboxMapper mapper) {
        this.mapper = mapper;
    }

    @Override
    @Transactional
    public long publish(String topic, String payload) {
        if (topic == null || topic.isBlank() || topic.length() > 64) {
            throw new IllegalArgumentException("topic 无效");
        }
        String body = payload == null ? "" : payload;
        if (body.length() > 4000) {
            throw new IllegalArgumentException("payload 过长");
        }
        MessageOutboxRow row = new MessageOutboxRow();
        // 未进入请求时 RegionContext 与全站一致回落 CN；没有区域对象时写空串。
        row.setRegion(RegionContext.getRegion() == null ? "" : RegionContext.getRegion().name());
        row.setTopic(topic.trim());
        row.setPayload(body);
        row.setStatus(1);
        mapper.insert(row);
        return row.getId();
    }
}
