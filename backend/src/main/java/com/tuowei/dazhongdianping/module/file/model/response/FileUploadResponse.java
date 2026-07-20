package com.tuowei.dazhongdianping.module.file.model.response;

public record FileUploadResponse(
        String url,
        String fileName,
        String contentType,
        long size
) {
}
