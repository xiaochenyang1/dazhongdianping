package com.tuowei.dazhongdianping.module.file.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.file.model.response.FileUploadResponse;
import com.tuowei.dazhongdianping.module.file.service.PublicFileService;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/c/v1/files")
public class PublicFileController {

    private final PublicFileService publicFileService;

    public PublicFileController(PublicFileService publicFileService) {
        this.publicFileService = publicFileService;
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<FileUploadResponse> upload(@RequestParam("file") MultipartFile file) {
        return ApiResponse.success("图片上传成功", "file.upload_success", publicFileService.uploadImage(file));
    }

    @GetMapping("/{fileName:.+}")
    public ResponseEntity<Resource> open(@PathVariable String fileName) {
        return publicFileService.openFile(fileName);
    }
}
