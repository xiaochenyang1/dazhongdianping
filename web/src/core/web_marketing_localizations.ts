import type { Region } from '@/types/browse'
import type { WebLocaleTag } from '@/core/web_localizations'

export interface WebMarketingStrings {
  tag: WebLocaleTag
  center: {
    eyebrow: string
    title: string
    summary: string
    loadFailed: string
    claimFailed: string
    claimSuccess: (name: string) => string
    loading: string
    empty: string
    claim: string
    claiming: string
    claimed: string
    soldOut: string
    noThreshold: string
    thresholdLabel: (amount: number, currency: string) => string
    validDays: (days: number) => string
  }
  wallet: {
    eyebrow: string
    title: string
    summary: string
    loadFailed: string
    loading: string
    empty: string
    all: string
    statusText: (status: number, fallback?: string) => string
    noThreshold: string
    thresholdLabel: (amount: number, currency: string) => string
    expiresAt: string
    noExpiry: string
  }
  checkout: {
    couponLabel: string
    noCoupon: string
    noneUsable: string
    discountLabel: (amount: number, currency: string) => string
    optionLabel: (name: string, amount: number, currency: string) => string
  }
  errorTranslations: Record<string, string>
}

const zhCnStrings: WebMarketingStrings = {
  tag: 'zh-CN',
  center: {
    eyebrow: '领券中心',
    title: '平台券先领后用，下单自动抵扣。',
    summary: '满减券和新客立减都在这里，领取后进入"我的营销券"。',
    loadFailed: '领券中心加载失败',
    claimFailed: '领取失败',
    claimSuccess: (name) => `已领取「${name}」`,
    loading: '券列表加载中...',
    empty: '当前区域暂无可领取的券。',
    claim: '立即领取',
    claiming: '领取中...',
    claimed: '已领取',
    soldOut: '已领完',
    noThreshold: '无门槛',
    thresholdLabel: (amount, currency) => `满 ${amount} ${currency} 可用`,
    validDays: (days) => `领取后 ${days} 天内有效`,
  },
  wallet: {
    eyebrow: '我的营销券',
    title: '领到的满减券和立减券都在这里。',
    summary: '用券下单会自动锁定，取消订单后券会退回。',
    loadFailed: '营销券加载失败',
    loading: '营销券加载中...',
    empty: '还没有营销券，去领券中心看看。',
    all: '全部',
    statusText: (status, fallback = '') => ({ 1: '未使用', 2: '已使用', 3: '已过期' } as Record<number, string>)[status] ?? fallback,
    noThreshold: '无门槛',
    thresholdLabel: (amount, currency) => `满 ${amount} ${currency}`,
    expiresAt: '有效期至',
    noExpiry: '长期有效',
  },
  checkout: {
    couponLabel: '使用营销券',
    noCoupon: '不使用券',
    noneUsable: '暂无可用券',
    discountLabel: (amount, currency) => `已优惠 ${amount} ${currency}`,
    optionLabel: (name, amount, currency) => `${name}（减 ${amount} ${currency}）`,
  },
  errorTranslations: {
    'marketing.coupon_claimed': '领取成功',
  },
}

const enStrings: WebMarketingStrings = {
  tag: 'en',
  center: {
    eyebrow: 'Coupon center',
    title: 'Claim platform coupons, redeemed automatically at checkout.',
    summary: 'Threshold and new-customer coupons live here; claimed ones move to your wallet.',
    loadFailed: 'Failed to load the coupon center',
    claimFailed: 'Failed to claim',
    claimSuccess: (name) => `Claimed "${name}"`,
    loading: 'Loading coupons...',
    empty: 'No coupons available in this region yet.',
    claim: 'Claim',
    claiming: 'Claiming...',
    claimed: 'Claimed',
    soldOut: 'Sold out',
    noThreshold: 'No minimum',
    thresholdLabel: (amount, currency) => `Spend ${amount} ${currency}`,
    validDays: (days) => `Valid for ${days} days after claiming`,
  },
  wallet: {
    eyebrow: 'My coupons',
    title: 'All your claimed threshold and instant-discount coupons.',
    summary: 'A coupon is locked when used on an order and released if the order is cancelled.',
    loadFailed: 'Failed to load coupons',
    loading: 'Loading coupons...',
    empty: 'No coupons yet — check the coupon center.',
    all: 'All',
    statusText: (status, fallback = '') => ({ 1: 'Unused', 2: 'Used', 3: 'Expired' } as Record<number, string>)[status] ?? fallback,
    noThreshold: 'No minimum',
    thresholdLabel: (amount, currency) => `Spend ${amount} ${currency}`,
    expiresAt: 'Valid until',
    noExpiry: 'No expiry',
  },
  checkout: {
    couponLabel: 'Use a coupon',
    noCoupon: 'No coupon',
    noneUsable: 'No usable coupon',
    discountLabel: (amount, currency) => `Saved ${amount} ${currency}`,
    optionLabel: (name, amount, currency) => `${name} (−${amount} ${currency})`,
  },
  errorTranslations: {
    'marketing.coupon_claimed': 'Claimed successfully',
  },
}

const STRINGS: Record<Region, WebMarketingStrings> = { CN: zhCnStrings, EU: enStrings }
const HAN_TEXT = /\p{Script=Han}/u

export function marketingStringsForRegion(region: Region) {
  return STRINGS[region]
}

export function localizeWebMarketingError(strings: WebMarketingStrings, error: unknown, fallback: string) {
  const messageKey = (error as { messageKey?: string })?.messageKey
  if (messageKey && strings.errorTranslations[messageKey]) return strings.errorTranslations[messageKey]
  if (!(error instanceof Error)) return fallback
  if (strings.tag === 'zh-CN' || !HAN_TEXT.test(error.message)) return error.message || fallback
  return fallback
}
