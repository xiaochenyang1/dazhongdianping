package com.tuowei.dazhongdianping.module.browse.model;

import lombok.Data;

@Data
public class SearchSuggestionRow {
    private String term;
    private String type;
    private Long refId;
}
