package com.tuowei.dazhongdianping.module.file.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = {
        "spring.servlet.multipart.max-file-size=10MB",
        "spring.servlet.multipart.max-request-size=20MB"
})
@AutoConfigureMockMvc
class PublicFileControllerTest {

    private static final Path TEST_UPLOAD_DIR = createUploadDir();
    private static final String TEST_DB_NAME = "fileuploadtest-" + UUID.randomUUID();

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("app.file-storage.base-dir", () -> TEST_UPLOAD_DIR.toString());
        registry.add(
                "spring.datasource.url",
                () -> "jdbc:h2:mem:%s;MODE=MYSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE".formatted(TEST_DB_NAME)
        );
    }

    @AfterAll
    static void cleanup() throws IOException {
        if (!Files.exists(TEST_UPLOAD_DIR)) {
            return;
        }
        try (var paths = Files.walk(TEST_UPLOAD_DIR)) {
            paths.sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (IOException exception) {
                            throw new UncheckedIOException(exception);
                        }
                    });
        } catch (UncheckedIOException exception) {
            throw exception.getCause();
        }
    }

    @Test
    void shouldRequireLoginWhenUploadingImage() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "demo.png",
                MediaType.IMAGE_PNG_VALUE,
                samplePngBytes()
        );

        mockMvc.perform(multipart("/api/c/v1/files/upload").file(file))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldUploadImageAndServeItPublicly() throws Exception {
        String userToken = registerUser("file-upload@example.com", "上传用户");
        byte[] imageBytes = samplePngBytes();
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "demo.png",
                MediaType.IMAGE_PNG_VALUE,
                imageBytes
        );

        MvcResult uploadResult = mockMvc.perform(multipart("/api/c/v1/files/upload")
                        .file(file)
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.url").value(org.hamcrest.Matchers.startsWith("/api/c/v1/files/")))
                .andExpect(jsonPath("$.data.contentType").value(MediaType.IMAGE_PNG_VALUE))
                .andReturn();

        String fileUrl = readText(uploadResult, "/data/url");

        mockMvc.perform(get(fileUrl))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", org.hamcrest.Matchers.startsWith(MediaType.IMAGE_PNG_VALUE)))
                .andExpect(content().bytes(imageBytes));
    }

    @Test
    void shouldRejectNonImageFile() throws Exception {
        String userToken = registerUser("file-text@example.com", "文本用户");
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "note.txt",
                MediaType.TEXT_PLAIN_VALUE,
                "not-image".getBytes()
        );

        mockMvc.perform(multipart("/api/c/v1/files/upload")
                        .file(file)
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void shouldRejectOversizedImage() throws Exception {
        String userToken = registerUser("file-large@example.com", "大图用户");
        byte[] bytes = new byte[5 * 1024 * 1024 + 1];
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "huge.png",
                MediaType.IMAGE_PNG_VALUE,
                bytes
        );

        mockMvc.perform(multipart("/api/c/v1/files/upload")
                        .file(file)
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("单张图片不能超过 5MB"));
    }

    private String registerUser(String account, String nickname) throws Exception {
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post("/api/c/v1/auth/send-code")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "web-file-001"
                                }
                                """.formatted(account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        MvcResult registerResult = mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "%s",
                                  "preferredRegion": "CN"
                                }
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andReturn();
        return readText(registerResult, "/data/accessToken");
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }

    private byte[] samplePngBytes() {
        try {
            BufferedImage bufferedImage = new BufferedImage(2, 2, BufferedImage.TYPE_INT_RGB);
            bufferedImage.setRGB(0, 0, 0xF97316);
            bufferedImage.setRGB(1, 0, 0x0F766E);
            bufferedImage.setRGB(0, 1, 0x1F2937);
            bufferedImage.setRGB(1, 1, 0xFFFFFF);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            ImageIO.write(bufferedImage, "png", outputStream);
            return outputStream.toByteArray();
        } catch (IOException exception) {
            throw new UncheckedIOException(exception);
        }
    }

    private static Path createUploadDir() {
        try {
            return Files.createTempDirectory("dzdp-upload-test-");
        } catch (IOException exception) {
            throw new UncheckedIOException(exception);
        }
    }
}
