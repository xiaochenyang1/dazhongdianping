package com.tuowei.dazhongdianping.module.file.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.config.FileStorageProperties;
import com.tuowei.dazhongdianping.module.file.model.response.FileUploadResponse;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;

class PublicFileServiceS3Test {

    @Test
    void shouldUploadImageToS3WhenProviderIsS3() {
        FileStorageProperties properties = new FileStorageProperties();
        properties.setProvider(FileStorageProperties.Provider.S3);
        properties.getS3().setBucket("dzdp-test");
        properties.getS3().setPublicBaseUrl("https://cdn.example.test/uploads");

        S3Client s3Client = mock(S3Client.class);
        when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                .thenReturn(PutObjectResponse.builder().eTag("etag").build());

        PublicFileService service = new PublicFileService(properties, providerOf(s3Client));

        FileUploadResponse response = service.uploadImage(new MockMultipartFile(
                "file",
                "demo.png",
                MediaType.IMAGE_PNG_VALUE,
                samplePngBytes()
        ));

        assertThat(response.url()).startsWith("https://cdn.example.test/uploads/");
        assertThat(response.fileName()).endsWith(".png");
        assertThat(response.contentType()).isEqualTo(MediaType.IMAGE_PNG_VALUE);
        verify(s3Client).putObject(any(PutObjectRequest.class), any(RequestBody.class));
    }

    @Test
    void shouldStreamFileFromS3WhenProviderIsS3() throws Exception {
        FileStorageProperties properties = new FileStorageProperties();
        properties.setProvider(FileStorageProperties.Provider.S3);
        properties.getS3().setBucket("dzdp-test");

        byte[] png = samplePngBytes();
        S3Client s3Client = mock(S3Client.class);
        when(s3Client.getObject(any(GetObjectRequest.class)))
                .thenReturn(new ResponseInputStream<>(
                        GetObjectResponse.builder().contentType(MediaType.IMAGE_PNG_VALUE).build(),
                        new ByteArrayInputStream(png)
                ));

        PublicFileService service = new PublicFileService(properties, providerOf(s3Client));

        ResponseEntity<Resource> response = service.openFile("20260812-abcdef.png");

        assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
        assertThat(response.getHeaders().getContentType()).isEqualTo(MediaType.IMAGE_PNG);
        Resource body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.getContentAsByteArray()).isEqualTo(png);
        verify(s3Client).getObject(any(GetObjectRequest.class));
    }

    private ObjectProvider<S3Client> providerOf(S3Client s3Client) {
        return new ObjectProvider<>() {
            @Override
            public S3Client getObject(Object... args) {
                return s3Client;
            }

            @Override
            public S3Client getIfAvailable() {
                return s3Client;
            }

            @Override
            public S3Client getIfUnique() {
                return s3Client;
            }

            @Override
            public S3Client getObject() {
                return s3Client;
            }
        };
    }

    private byte[] samplePngBytes() {
        try {
            BufferedImage bufferedImage = new BufferedImage(2, 2, BufferedImage.TYPE_INT_RGB);
            bufferedImage.setRGB(0, 0, 0xF97316);
            bufferedImage.setRGB(1, 0, 0x0F766E);
            bufferedImage.setRGB(0, 1, 0x1F2937);
            bufferedImage.setRGB(1, 1, 0xFFFFFF);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            javax.imageio.ImageIO.write(bufferedImage, "png", outputStream);
            return outputStream.toByteArray();
        } catch (IOException exception) {
            throw new UncheckedIOException(exception);
        }
    }
}
