package com.tuowei.dazhongdianping.common.messaging;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.messaging.mapper.MessageOutboxMapper;
import com.tuowei.dazhongdianping.module.messaging.model.MessageOutboxRow;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class MessagePublisherTest {

    @Autowired private MessagePublisher publisher;
    @Autowired private MessageOutboxMapper mapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void publishWritesOutboxRow() {
        long id = publisher.publish("invoice.requested", "{}");

        MessageOutboxRow row = mapper.selectById(id);
        assertNotNull(row);
        assertEquals(1, row.getStatus());
        assertEquals("invoice.requested", row.getTopic());
        assertEquals("{}", row.getPayload());
        assertNotNull(row.getPublishedAt());

        Integer status = jdbcTemplate.queryForObject(
                "SELECT status FROM message_outbox WHERE id = ? AND topic = ?",
                Integer.class, id, "invoice.requested");
        assertEquals(1, status);
    }

    @Test
    void publishUsesRegionContext() {
        RegionContext.setRegion(Region.EU);
        try {
            long id = publisher.publish("invoice.requested", "{\"region\":\"EU\"}");
            MessageOutboxRow row = mapper.selectById(id);
            assertEquals("EU", row.getRegion());
            assertEquals(1, row.getStatus());
        } finally {
            RegionContext.clear();
        }
    }
}
