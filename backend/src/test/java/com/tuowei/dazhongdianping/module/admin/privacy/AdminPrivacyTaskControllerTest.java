package com.tuowei.dazhongdianping.module.admin.privacy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminPrivacyTaskControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @BeforeEach
    void seedPrivacyTasks() {
        jdbc.update(
                """
                INSERT INTO privacy_export_task(id,user_id,scope_json,format,status,file_name,file_path,expire_at,fail_reason,created_at,updated_at) VALUES
                (9101,9001,'["account","reviews"]','zip',2,'privacy-export-9101.zip','local-storage/privacy-exports/9101.zip',TIMESTAMP '2026-07-25 09:00:00','',TIMESTAMP '2026-07-19 09:00:00',TIMESTAMP '2026-07-19 09:05:00'),
                (9102,9002,'["messages"]','zip',4,'','',NULL,'导出压缩失败',TIMESTAMP '2026-07-19 10:00:00',TIMESTAMP '2026-07-19 10:06:00')
                """
        );
        jdbc.update(
                """
                INSERT INTO privacy_delete_task(id,user_id,verify_type,account_snapshot,reason,status,cooling_off_expire_at,completed_at,cancelled_at,created_at,updated_at) VALUES
                (9201,9001,'code','demo.cn@example.com','不再使用',1,TIMESTAMP '2026-07-26 12:00:00',NULL,NULL,TIMESTAMP '2026-07-19 11:00:00',TIMESTAMP '2026-07-19 11:10:00')
                """
        );
    }

    @Test
    void shouldListCombinedPrivacyTasksInReverseChronologicalOrder() throws Exception {
        mockMvc.perform(get("/api/admin/v1/privacy/tasks")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .param("page", "1")
                        .param("pageSize", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(3))
                .andExpect(jsonPath("$.data.hasMore").value(true))
                .andExpect(jsonPath("$.data.list[0].id").value(9201))
                .andExpect(jsonPath("$.data.list[0].taskType").value(2))
                .andExpect(jsonPath("$.data.list[0].taskTypeText").value("账号删除"))
                .andExpect(jsonPath("$.data.list[0].userNickname").value("审评员阿木"))
                .andExpect(jsonPath("$.data.list[1].id").value(9102))
                .andExpect(jsonPath("$.data.list[1].taskType").value(1))
                .andExpect(jsonPath("$.data.list[1].statusText").value("失败"));
    }

    @Test
    void shouldFilterPrivacyTasksByTaskTypeStatusAndKeyword() throws Exception {
        mockMvc.perform(get("/api/admin/v1/privacy/tasks")
                        .header("Authorization", bearer(login("admin", "admin123456")))
                        .param("taskType", "1")
                        .param("status", "2")
                        .param("keyword", "account"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(9101))
                .andExpect(jsonPath("$.data.list[0].modules[0]").value("account"))
                .andExpect(jsonPath("$.data.list[0].fileName").value("privacy-export-9101.zip"))
                .andExpect(jsonPath("$.data.list[0].account").value("demo.cn@example.com"));
    }

    private String login(String account, String password) throws Exception {
        var result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"%s","password":"%s"}
                                """.formatted(account, password)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
