package com.tuowei.dazhongdianping.module.search.service;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ShopNamePinyinConverterTest {

    private final ShopNamePinyinConverter converter = new ShopNamePinyinConverter();

    @Test
    void shouldConvertChineseShopNameToSearchablePinyin() {
        assertThat(converter.convert("渝里火锅 徐汇店"))
                .isEqualTo("yulihuoguoxuhuidian");
    }

    @Test
    void shouldPreserveLettersAndNumbersInLowercase() {
        assertThat(converter.convert("Cafe 88"))
                .isEqualTo("cafe88");
    }
}
