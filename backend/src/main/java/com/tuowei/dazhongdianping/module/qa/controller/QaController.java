package com.tuowei.dazhongdianping.module.qa.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.qa.model.request.QaContentRequest;
import com.tuowei.dazhongdianping.module.qa.service.QaService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/shops/{shopId}/questions")
public class QaController {

    private final QaService service;

    public QaController(QaService service) {
        this.service = service;
    }

    /** 问题列表（游客可读）。 */
    @GetMapping
    public ApiResponse<PageResult<Map<String, Object>>> questions(
            @PathVariable Long shopId,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        return ApiResponse.success(service.questions(shopId, page, pageSize));
    }

    /** 提问（需登录）。 */
    @PostMapping
    public ApiResponse<Map<String, Object>> ask(
            @PathVariable Long shopId, @Valid @RequestBody QaContentRequest request) {
        return ApiResponse.success("提问已发布", "qa.question_created", service.ask(shopId, request.content()));
    }

    /** 回答列表（游客可读）。 */
    @GetMapping("/{questionId}/answers")
    public ApiResponse<List<Map<String, Object>>> answers(
            @PathVariable Long shopId, @PathVariable Long questionId) {
        return ApiResponse.success(service.answers(shopId, questionId));
    }

    /** 回答（需登录）。 */
    @PostMapping("/{questionId}/answers")
    public ApiResponse<Map<String, Object>> answer(
            @PathVariable Long shopId, @PathVariable Long questionId,
            @Valid @RequestBody QaContentRequest request) {
        return ApiResponse.success("回答已发布", "qa.answer_created", service.answer(shopId, questionId, request.content()));
    }
}
