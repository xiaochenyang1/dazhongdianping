package com.tuowei.dazhongdianping.module.browse.model.response;

public record SearchSuggestionResponse(
        String term,
        String type,
        Long refId
) {
}
