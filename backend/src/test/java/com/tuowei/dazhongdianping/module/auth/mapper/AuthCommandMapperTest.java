package com.tuowei.dazhongdianping.module.auth.mapper;

import static org.junit.jupiter.api.Assertions.assertEquals;

import com.tuowei.dazhongdianping.module.auth.model.VerificationCodeRow;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AuthCommandMapperTest {

    @Autowired
    private AuthCommandMapper authCommandMapper;

    @Test
    void shouldConsumeUnusedVerificationCodeOnlyOnce() {
        VerificationCodeRow row = verificationCode("mapper-once@example.com", LocalDateTime.now().plusMinutes(5));
        authCommandMapper.insertVerificationCode(row);

        assertEquals(1, authCommandMapper.markVerificationCodeUsed(row.getId()));
        assertEquals(0, authCommandMapper.markVerificationCodeUsed(row.getId()));
    }

    @Test
    void shouldNotConsumeExpiredVerificationCode() {
        VerificationCodeRow row = verificationCode("mapper-expired@example.com", LocalDateTime.now().minusMinutes(1));
        authCommandMapper.insertVerificationCode(row);

        assertEquals(0, authCommandMapper.markVerificationCodeUsed(row.getId()));
    }

    private VerificationCodeRow verificationCode(String target, LocalDateTime expireAt) {
        VerificationCodeRow row = new VerificationCodeRow();
        row.setScene("login");
        row.setTargetType(1);
        row.setTarget(target);
        row.setCodeHash("test-code-hash");
        row.setDeviceId("test-device");
        row.setRequestIp("127.0.0.1");
        row.setStatus(0);
        row.setExpireAt(expireAt);
        return row;
    }
}
