package com.tuowei.dazhongdianping.module.message.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.message.model.request.ReportMessageRequest;
import com.tuowei.dazhongdianping.module.message.model.request.SendMessageRequest;
import com.tuowei.dazhongdianping.module.message.model.response.BlockStatusResponse;
import com.tuowei.dazhongdianping.module.message.model.response.BlockedUserResponse;
import com.tuowei.dazhongdianping.module.message.model.response.ConversationResponse;
import com.tuowei.dazhongdianping.module.message.model.response.MessageReportResponse;
import com.tuowei.dazhongdianping.module.message.model.response.MessageResponse;
import com.tuowei.dazhongdianping.module.message.model.response.ReadMessagesResponse;
import com.tuowei.dazhongdianping.module.message.service.MessageService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/messages")
public class MessageController {
    private final MessageService service;
    public MessageController(MessageService service) { this.service = service; }
    @GetMapping("/conversations") public ApiResponse<PageResult<ConversationResponse>> conversations(
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.conversations(page, pageSize));
    }
    @GetMapping("/conversations/{id}") public ApiResponse<PageResult<MessageResponse>> messages(@PathVariable Long id,
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.messages(id, page, pageSize));
    }
    @PostMapping("/send") public ApiResponse<MessageResponse> send(@Valid @RequestBody SendMessageRequest request) {
        return ApiResponse.success(service.send(request));
    }
    @PostMapping("/conversations/{id}/read") public ApiResponse<ReadMessagesResponse> read(@PathVariable Long id) {
        return ApiResponse.success(service.markRead(id));
    }
    @PutMapping("/blocks/{userId}") public ApiResponse<BlockStatusResponse> block(@PathVariable Long userId) {
        return ApiResponse.success(service.block(userId));
    }
    @DeleteMapping("/blocks/{userId}") public ApiResponse<BlockStatusResponse> unblock(@PathVariable Long userId) {
        return ApiResponse.success(service.unblock(userId));
    }
    @GetMapping("/blocks") public ApiResponse<PageResult<BlockedUserResponse>> blocks(
            @RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "20") Integer pageSize) {
        return ApiResponse.success(service.blocks(page, pageSize));
    }
    @PostMapping("/report") public ApiResponse<MessageReportResponse> report(@Valid @RequestBody ReportMessageRequest request) {
        return ApiResponse.success(service.report(request));
    }
}
