package com.tuowei.dazhongdianping.module.search.service;

import net.sourceforge.pinyin4j.PinyinHelper;
import net.sourceforge.pinyin4j.format.HanyuPinyinCaseType;
import net.sourceforge.pinyin4j.format.HanyuPinyinOutputFormat;
import net.sourceforge.pinyin4j.format.HanyuPinyinToneType;
import net.sourceforge.pinyin4j.format.HanyuPinyinVCharType;
import net.sourceforge.pinyin4j.format.exception.BadHanyuPinyinOutputFormatCombination;
import org.springframework.stereotype.Component;

@Component
public class ShopNamePinyinConverter {

    private final HanyuPinyinOutputFormat outputFormat;

    public ShopNamePinyinConverter() {
        outputFormat = new HanyuPinyinOutputFormat();
        outputFormat.setCaseType(HanyuPinyinCaseType.LOWERCASE);
        outputFormat.setToneType(HanyuPinyinToneType.WITHOUT_TONE);
        outputFormat.setVCharType(HanyuPinyinVCharType.WITH_V);
    }

    public String convert(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        StringBuilder result = new StringBuilder();
        for (char character : value.toCharArray()) {
            if (Character.isLetterOrDigit(character) && character < 128) {
                result.append(Character.toLowerCase(character));
                continue;
            }
            try {
                String[] pinyin = PinyinHelper.toHanyuPinyinStringArray(character, outputFormat);
                if (pinyin != null && pinyin.length > 0) {
                    result.append(pinyin[0]);
                }
            } catch (BadHanyuPinyinOutputFormatCombination exception) {
                throw new IllegalStateException("拼音转换配置错误", exception);
            }
        }
        return result.toString();
    }
}
