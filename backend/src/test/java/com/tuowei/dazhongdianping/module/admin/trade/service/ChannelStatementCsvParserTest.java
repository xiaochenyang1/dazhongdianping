package com.tuowei.dazhongdianping.module.admin.trade.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.tuowei.dazhongdianping.module.admin.trade.service.ChannelStatementCsvParser.StatementRecord;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.junit.jupiter.api.Test;

class ChannelStatementCsvParserTest {

    @Test
    void shouldParseQuotedCommaEscapedQuoteAndMultilineField() {
        String csv = "\"Payment Intent ID\",Gross,Description\r\n"
                + "pi_1,12.34,\"Cafe, \"\"special\"\"\"\r\n"
                + "pi_2,5.00,\"line one\nline two\"\r\n";

        List<StatementRecord> records = ChannelStatementCsvParser.parse(bytes(csv));

        assertThat(records).hasSize(2);
        assertThat(records.get(0).lineNo()).isEqualTo(2);
        assertThat(records.get(0).first("payment_intent_id")).isEqualTo("pi_1");
        assertThat(records.get(0).first("gross")).isEqualTo("12.34");
        assertThat(records.get(0).first("description")).isEqualTo("Cafe, \"special\"");
        assertThat(records.get(1).lineNo()).isEqualTo(3);
        assertThat(records.get(1).first("description")).isEqualTo("line one\nline two");
    }

    @Test
    void shouldStripUtf8BomNormalizeHeadersAndResolveAliases() {
        String csv = "\uFEFFTransaction Type,Transaction-ID,Amount\n"
                + "refund,re_123,19.95\n";

        StatementRecord record = ChannelStatementCsvParser.parse(bytes(csv)).get(0);

        assertThat(record.values())
                .containsEntry("transaction_type", "refund")
                .containsEntry("transaction_id", "re_123")
                .containsEntry("amount", "19.95");
        assertThat(record.first("missing", "transaction_id")).isEqualTo("re_123");
    }

    @Test
    void shouldAllowFiveThousandRowsAndRejectTheNextNonBlankRow() {
        String allowed = csvWithRows(5_000);

        assertThat(ChannelStatementCsvParser.parse(bytes(allowed))).hasSize(5_000);

        assertThatThrownBy(() -> ChannelStatementCsvParser.parse(bytes(allowed + "row-5001\n")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("单个渠道账单最多允许 5000 行数据");
    }

    @Test
    void shouldRejectEmptyHeaderOnlyAndUnclosedQuotedCsv() {
        assertThatThrownBy(() -> ChannelStatementCsvParser.parse(new byte[0]))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("渠道账单 CSV 不能为空");
        assertThatThrownBy(() -> ChannelStatementCsvParser.parse(bytes(" , \nvalue,data\n")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("渠道账单 CSV 缺少表头");
        assertThatThrownBy(() -> ChannelStatementCsvParser.parse(bytes("id,name")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("渠道账单 CSV 没有数据行");
        assertThatThrownBy(() -> ChannelStatementCsvParser.parse(bytes("id,description\n1,\"not closed")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("渠道账单 CSV 第 2 行引号未闭合");
    }

    private String csvWithRows(int count) {
        StringBuilder csv = new StringBuilder("id\n");
        for (int index = 1; index <= count; index++) {
            csv.append("row-").append(index).append('\n');
        }
        return csv.toString();
    }

    private byte[] bytes(String value) {
        return value.getBytes(StandardCharsets.UTF_8);
    }
}
