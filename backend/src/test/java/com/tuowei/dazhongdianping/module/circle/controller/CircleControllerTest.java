package com.tuowei.dazhongdianping.module.circle.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class CircleControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbcTemplate;

    @Test
    void shouldListAndReadOnlyCurrentRegionForGuestsAndMembers() throws Exception {
        long euCircle = insertCircle("EU", "伦敦生活圈", 1, 10);
        long cnCircle = insertCircle("CN", "上海探店圈", 1, 20);
        UserAccess member = registerUser("圈子成员");

        mockMvc.perform(get("/api/c/v1/groups").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(euCircle))
                .andExpect(jsonPath("$.data.list[0].name").value("伦敦生活圈"))
                .andExpect(jsonPath("$.data.list[0].joinedByCurrentUser").value(false));

        mockMvc.perform(get("/api/c/v1/groups/{id}", cnCircle).header("X-Region", "EU"))
                .andExpect(status().isNotFound());

        join(euCircle, member).andExpect(status().isOk());
        mockMvc.perform(get("/api/c/v1/groups/{id}", euCircle)
                        .header("Authorization", bearer(member.token())).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.joinedByCurrentUser").value(true))
                .andExpect(jsonPath("$.data.memberCount").value(1));

        mockMvc.perform(get("/api/c/v1/groups/{id}/members", euCircle).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(member.id()))
                .andExpect(jsonPath("$.data.list[0].nickname").value("圈子成员"));
    }

    @Test
    void shouldJoinAndLeaveIdempotentlyWithoutCorruptingMemberCount() throws Exception {
        long circleId = insertCircle("EU", "欧洲留学圈", 1, 10);
        UserAccess user = registerUser("留学生");

        join(circleId, user)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.joined").value(true))
                .andExpect(jsonPath("$.data.memberCount").value(1));
        join(circleId, user)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.memberCount").value(1));

        mockMvc.perform(get("/api/c/v1/groups").param("joined", "true")
                        .header("Authorization", bearer(user.token())).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(circleId));

        leave(circleId, user)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.joined").value(false))
                .andExpect(jsonPath("$.data.memberCount").value(0));
        leave(circleId, user)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.memberCount").value(0));
    }

    @Test
    void shouldRequireLoginForMembershipAndRejectDisabledCircle() throws Exception {
        long circleId = insertCircle("EU", "停用圈子", 2, 10);
        UserAccess user = registerUser("停用测试用户");

        mockMvc.perform(put("/api/c/v1/groups/{id}/membership", circleId).header("X-Region", "EU"))
                .andExpect(status().isUnauthorized());
        join(circleId, user).andExpect(status().isNotFound());
        mockMvc.perform(get("/api/c/v1/groups/{id}", circleId).header("X-Region", "EU"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldAllowOnlyMembersToCreateAndListCirclePosts() throws Exception {
        long circleId = insertCircle("EU", "伦敦探店圈", 1, 10);
        UserAccess member = registerUser("圈子作者");
        UserAccess outsider = registerUser("圈外用户");

        createCirclePost(circleId, outsider, "圈外发帖")
                .andExpect(status().isConflict());

        join(circleId, member).andExpect(status().isOk());
        MvcResult created = createCirclePost(circleId, member, "圈内真实帖子")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.circleId").value(circleId))
                .andExpect(jsonPath("$.data.circleName").value("伦敦探店圈"))
                .andReturn();
        long postId = readLong(created, "/data/id");
        jdbcTemplate.update("UPDATE post SET audit_status=1,status=1 WHERE id=?", postId);

        mockMvc.perform(get("/api/c/v1/groups/{id}/posts", circleId).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(postId))
                .andExpect(jsonPath("$.data.list[0].circleName").value("伦敦探店圈"));

        leave(circleId, member).andExpect(status().isOk());
        mockMvc.perform(get("/api/c/v1/groups/{id}/posts", circleId).header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1));
    }

    private org.springframework.test.web.servlet.ResultActions join(long circleId, UserAccess user) throws Exception {
        return mockMvc.perform(put("/api/c/v1/groups/{id}/membership", circleId)
                .header("Authorization", bearer(user.token())).header("X-Region", "EU"));
    }

    private org.springframework.test.web.servlet.ResultActions leave(long circleId, UserAccess user) throws Exception {
        return mockMvc.perform(delete("/api/c/v1/groups/{id}/membership", circleId)
                .header("Authorization", bearer(user.token())).header("X-Region", "EU"));
    }

    private org.springframework.test.web.servlet.ResultActions createCirclePost(long circleId, UserAccess user, String title)
            throws Exception {
        return mockMvc.perform(post("/api/c/v1/posts")
                .header("Authorization", bearer(user.token())).header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"circleId":%d,"title":"%s","content":"圈子帖子内容","contentType":1,"images":[],"topics":[]}
                        """.formatted(circleId, title)));
    }

    private long insertCircle(String region, String name, int status, int sort) {
        jdbcTemplate.update("""
                INSERT INTO circle(region,name,description,cover_url,member_count,post_count,sort,status,created_by,is_deleted)
                VALUES(?,?,?,'',0,0,?,?,1,FALSE)
                """, region, name, name + "简介", sort, status);
        return jdbcTemplate.queryForObject("SELECT id FROM circle WHERE region=? AND name=?", Long.class, region, name);
    }

    private UserAccess registerUser(String nickname) throws Exception {
        String account = "circle-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> { request.setRemoteAddr("10.98.12.9"); return request; })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"scene":"register","type":"email","account":"%s","deviceId":"circle-test-%s"}
                                """.formatted(account, UUID.randomUUID())))
                .andExpect(status().isOk());
        MvcResult register = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"type":"email","account":"%s","code":"123456","password":"Passw0rd!","nickname":"%s","preferredRegion":"EU"}
                                """.formatted(account, nickname)))
                .andExpect(status().isOk()).andReturn();
        String token = readText(register, "/data/accessToken");
        MvcResult me = mockMvc.perform(get("/api/c/v1/user/me")
                        .header("Authorization", bearer(token)).header("X-Region", "EU"))
                .andExpect(status().isOk()).andReturn();
        return new UserAccess(readLong(me, "/data/id"), token);
    }

    private String bearer(String token) { return "Bearer " + token; }
    private String readText(MvcResult result, String pointer) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at(pointer).asText();
    }
    private long readLong(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asLong();
    }
    private record UserAccess(long id, String token) {}
}
