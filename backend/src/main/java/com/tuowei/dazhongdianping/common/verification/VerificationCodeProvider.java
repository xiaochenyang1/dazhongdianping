package com.tuowei.dazhongdianping.common.verification;

/**
 * 验证码发送通道抽象。
 *
 * <p>参照 {@code PushProvider} 模式:Bean 恒实例化,是否真正激活由运行时
 * {@link #isConfigured()} 决定,不用 {@code @ConditionalOnProperty}。
 * 放在 {@code common.verification} 包下(而非 {@code module.auth})以避开
 * {@code @MapperScan("...module")} 对 module 包下所有接口的 MyBatis 代理扫描。
 *
 * <p>真实渠道(Aliyun SMS / SMTP)接入时新增实现并令 {@code isConfigured()} 在凭证齐全时返回 true,
 * 用 {@code @Order} 保证优先于控制台 dev provider。
 */
public interface VerificationCodeProvider {

    String name();

    boolean isConfigured();

    /** @return 是否支持指定目标:targetType 1=email,2=phone。 */
    boolean supports(String target, int targetType);

    /**
     * 发送验证码。
     *
     * @param target     接收账号(邮箱或手机号)
     * @param targetType 1=email, 2=phone,与 {@code VerificationCodeRow.targetType} 一致
     * @param code       6 位验证码
     * @param scene      归一化后的小写场景(login/register/bind/reset/delete/appeal)
     * @throws VerificationCodeSendException 发送失败时抛出(unchecked,使事务回滚语义清晰)
     */
    void send(String target, int targetType, String code, String scene);
}
