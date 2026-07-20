package com.tuowei.dazhongdianping.module.file.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.config.FileStorageProperties;
import com.tuowei.dazhongdianping.module.file.model.response.FileUploadResponse;
import jakarta.annotation.PostConstruct;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.LocalDate;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import javax.imageio.ImageIO;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@Service
public class PublicFileService {

    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            MediaType.IMAGE_JPEG_VALUE,
            MediaType.IMAGE_PNG_VALUE,
            MediaType.IMAGE_GIF_VALUE
    );

    private final FileStorageProperties properties;
    private final Path baseDir;
    private final long maxImageBytes;
    private final S3Client s3Client;

    public PublicFileService(FileStorageProperties properties, ObjectProvider<S3Client> s3ClientProvider) {
        this.properties = properties;
        this.baseDir = Path.of(properties.getBaseDir()).toAbsolutePath().normalize();
        this.maxImageBytes = properties.getMaxImageBytes();
        this.s3Client = s3ClientProvider.getIfAvailable();
    }

    @PostConstruct
    public void init() {
        if (properties.getProvider() == FileStorageProperties.Provider.S3) {
            return;
        }
        try {
            Files.createDirectories(baseDir);
        } catch (IOException exception) {
            throw new IllegalStateException("本地上传目录初始化失败", exception);
        }
    }

    public FileUploadResponse uploadImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("请选择要上传的图片");
        }
        if (file.getSize() > maxImageBytes) {
            throw new IllegalArgumentException("单张图片不能超过 5MB");
        }

        ImageFormat imageFormat = resolveImageFormat(file);
        byte[] bytes = readFileBytes(file);
        ensureImageReadable(bytes);

        String fileName = buildStoredFileName(imageFormat.extension());
        if (properties.getProvider() == FileStorageProperties.Provider.S3) {
            return uploadToS3(fileName, imageFormat.contentType(), bytes);
        }

        Path target = baseDir.resolve(fileName).normalize();
        ensureInsideBaseDir(target);
        writeFile(target, bytes);

        return new FileUploadResponse(
                "/api/c/v1/files/" + fileName,
                fileName,
                imageFormat.contentType(),
                bytes.length
        );
    }

    private FileUploadResponse uploadToS3(String fileName, String contentType, byte[] bytes) {
        if (s3Client == null) {
            throw new IllegalStateException("S3 文件存储未配置客户端");
        }
        FileStorageProperties.S3 s3 = properties.getS3();
        if (!StringUtils.hasText(s3.getBucket())) {
            throw new IllegalStateException("S3 bucket 未配置");
        }

        s3Client.putObject(
                PutObjectRequest.builder()
                        .bucket(s3.getBucket())
                        .key(fileName)
                        .contentType(contentType)
                        .contentLength((long) bytes.length)
                        .build(),
                RequestBody.fromBytes(bytes)
        );

        return new FileUploadResponse(
                publicUrl(fileName),
                fileName,
                contentType,
                bytes.length
        );
    }

    private String publicUrl(String fileName) {
        String publicBaseUrl = properties.getS3().getPublicBaseUrl();
        if (StringUtils.hasText(publicBaseUrl)) {
            return publicBaseUrl.replaceAll("/+$", "") + "/" + fileName;
        }
        return "s3://" + properties.getS3().getBucket() + "/" + fileName;
    }

    public ResponseEntity<Resource> openFile(String fileName) {
        if (!StringUtils.hasText(fileName) || fileName.contains("/") || fileName.contains("\\") || fileName.contains("..")) {
            throw new NotFoundException("文件不存在");
        }

        Path filePath = baseDir.resolve(fileName).normalize();
        ensureInsideBaseDir(filePath);
        if (!Files.exists(filePath) || !Files.isRegularFile(filePath)) {
            throw new NotFoundException("文件不存在");
        }

        try {
            Resource resource = new UrlResource(filePath.toUri());
            MediaType mediaType = resolveResponseMediaType(filePath);

            return ResponseEntity.ok()
                    .cacheControl(CacheControl.noCache())
                    .contentType(mediaType)
                    .body(resource);
        } catch (IOException exception) {
            throw new IllegalStateException("读取文件失败", exception);
        }
    }

    private ImageFormat resolveImageFormat(MultipartFile file) {
        String contentType = normalizeContentType(file.getContentType());
        if (!ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new IllegalArgumentException("当前只支持 jpg、png、gif 图片");
        }
        return switch (contentType) {
            case MediaType.IMAGE_JPEG_VALUE -> new ImageFormat(MediaType.IMAGE_JPEG_VALUE, "jpg");
            case MediaType.IMAGE_GIF_VALUE -> new ImageFormat(MediaType.IMAGE_GIF_VALUE, "gif");
            default -> new ImageFormat(MediaType.IMAGE_PNG_VALUE, "png");
        };
    }

    private String normalizeContentType(String value) {
        if (!StringUtils.hasText(value)) {
            return "";
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }

    private byte[] readFileBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException exception) {
            throw new IllegalStateException("读取上传文件失败", exception);
        }
    }

    private void ensureImageReadable(byte[] bytes) {
        try (ByteArrayInputStream inputStream = new ByteArrayInputStream(bytes)) {
            BufferedImage bufferedImage = ImageIO.read(inputStream);
            if (bufferedImage == null) {
                throw new IllegalArgumentException("上传内容不是有效图片");
            }
        } catch (IOException exception) {
            throw new IllegalStateException("校验图片失败", exception);
        }
    }

    private String buildStoredFileName(String extension) {
        LocalDate now = LocalDate.now();
        return "%s-%s.%s".formatted(
                now.toString().replace("-", ""),
                UUID.randomUUID().toString().replace("-", ""),
                extension
        );
    }

    private void writeFile(Path target, byte[] bytes) {
        try {
            Files.write(target, bytes, StandardOpenOption.CREATE_NEW);
        } catch (IOException exception) {
            throw new IllegalStateException("保存上传文件失败", exception);
        }
    }

    private void ensureInsideBaseDir(Path target) {
        if (!target.startsWith(baseDir)) {
            throw new NotFoundException("文件不存在");
        }
    }

    private MediaType resolveResponseMediaType(Path filePath) throws IOException {
        String contentType = Files.probeContentType(filePath);
        if (StringUtils.hasText(contentType)) {
            return MediaType.parseMediaType(contentType);
        }
        String fileName = filePath.getFileName().toString().toLowerCase(Locale.ROOT);
        if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) {
            return MediaType.IMAGE_JPEG;
        }
        if (fileName.endsWith(".gif")) {
            return MediaType.IMAGE_GIF;
        }
        if (fileName.endsWith(".png")) {
            return MediaType.IMAGE_PNG;
        }
        return MediaType.APPLICATION_OCTET_STREAM;
    }

    private record ImageFormat(String contentType, String extension) {
    }
}
