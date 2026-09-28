package com.tuowei.dazhongdianping.common.moderation;

/**
 * 内容机审 SPI。接口放在 common，避免 {@code @MapperScan("...module")}
 * 把 module 下的非 Mapper 接口当成 MyBatis Mapper。
 */
public interface ContentModerationProvider {

    ModerationResult moderate(String region, String... texts);
}
