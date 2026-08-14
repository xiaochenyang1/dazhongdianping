package com.tuowei.dazhongdianping.module.admin.trade.service;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

final class ChannelStatementCsvParser {

    private static final int MAX_DATA_ROWS = 5_000;

    private ChannelStatementCsvParser() {
    }

    static List<StatementRecord> parse(byte[] content) {
        String csv = new String(content, StandardCharsets.UTF_8);
        List<CsvRow> rows = parseRows(csv);
        if (rows.isEmpty()) {
            throw new IllegalArgumentException("渠道账单 CSV 不能为空");
        }
        List<String> headers = rows.get(0).values().stream().map(ChannelStatementCsvParser::normalizeHeader).toList();
        if (headers.stream().allMatch(String::isBlank)) {
            throw new IllegalArgumentException("渠道账单 CSV 缺少表头");
        }
        List<StatementRecord> records = new ArrayList<>();
        for (int index = 1; index < rows.size(); index++) {
            CsvRow row = rows.get(index);
            if (row.values().stream().allMatch(String::isBlank)) {
                continue;
            }
            if (records.size() >= MAX_DATA_ROWS) {
                throw new IllegalArgumentException("单个渠道账单最多允许 5000 行数据");
            }
            Map<String, String> values = new LinkedHashMap<>();
            for (int column = 0; column < headers.size(); column++) {
                String header = headers.get(column);
                if (!header.isBlank() && !values.containsKey(header)) {
                    values.put(header, column < row.values().size() ? row.values().get(column).trim() : "");
                }
            }
            records.add(new StatementRecord(row.lineNo(), values));
        }
        if (records.isEmpty()) {
            throw new IllegalArgumentException("渠道账单 CSV 没有数据行");
        }
        return records;
    }

    private static List<CsvRow> parseRows(String csv) {
        List<CsvRow> rows = new ArrayList<>();
        List<String> fields = new ArrayList<>();
        StringBuilder field = new StringBuilder();
        boolean quoted = false;
        int line = 1;
        int rowLine = 1;
        for (int index = 0; index < csv.length(); index++) {
            char current = csv.charAt(index);
            if (quoted) {
                if (current == '"') {
                    if (index + 1 < csv.length() && csv.charAt(index + 1) == '"') {
                        field.append('"');
                        index++;
                    } else {
                        quoted = false;
                    }
                } else {
                    field.append(current);
                    if (current == '\n') {
                        line++;
                    }
                }
                continue;
            }
            if (current == '"' && field.length() == 0) {
                quoted = true;
            } else if (current == ',') {
                fields.add(field.toString());
                field.setLength(0);
            } else if (current == '\r' || current == '\n') {
                fields.add(field.toString());
                field.setLength(0);
                rows.add(new CsvRow(rowLine, List.copyOf(fields)));
                fields.clear();
                if (current == '\r' && index + 1 < csv.length() && csv.charAt(index + 1) == '\n') {
                    index++;
                }
                line++;
                rowLine = line;
            } else {
                field.append(current);
            }
        }
        if (quoted) {
            throw new IllegalArgumentException("渠道账单 CSV 第 " + rowLine + " 行引号未闭合");
        }
        if (field.length() > 0 || !fields.isEmpty()) {
            fields.add(field.toString());
            rows.add(new CsvRow(rowLine, List.copyOf(fields)));
        }
        return rows;
    }

    private static String normalizeHeader(String value) {
        String normalized = value == null ? "" : value.replace("\uFEFF", "").trim().toLowerCase(Locale.ROOT);
        return normalized.replaceAll("[^a-z0-9]+", "_").replaceAll("^_+|_+$", "");
    }

    record StatementRecord(int lineNo, Map<String, String> values) {
        String first(String... aliases) {
            for (String alias : aliases) {
                String value = values.get(alias);
                if (value != null && !value.isBlank()) {
                    return value.trim();
                }
            }
            return "";
        }
    }

    private record CsvRow(int lineNo, List<String> values) {
    }
}
