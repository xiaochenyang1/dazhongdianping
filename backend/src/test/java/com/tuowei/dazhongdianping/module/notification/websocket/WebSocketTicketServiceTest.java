package com.tuowei.dazhongdianping.module.notification.websocket;

import static org.junit.jupiter.api.Assertions.*;

import java.util.Map;
import org.junit.jupiter.api.Test;

class WebSocketTicketServiceTest {
    @Test
    void ticketIsSingleUseAndCarriesRegion() {
        WebSocketTicketService service = new WebSocketTicketService();
        Map<String, Object> issued = service.issue(42L, "EU");
        String value = (String) issued.get("ticket");
        WebSocketTicketService.Ticket ticket = service.consume(value);
        assertNotNull(ticket);
        assertEquals(42L, ticket.userId());
        assertEquals("EU", ticket.region());
        assertNull(service.consume(value));
    }
}
