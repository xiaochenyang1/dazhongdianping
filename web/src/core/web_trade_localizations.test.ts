import { describe, expect, it } from 'vitest'
import {
  formatWebTradeDate,
  localizeWebTradeError,
  tradeStringsForRegion,
} from './web_trade_localizations'

describe('web trade localizations', () => {
  it('localizes backend status fallbacks and timeline remarks for EU', () => {
    const copy = tradeStringsForRegion('EU')

    expect(copy.statuses.pay(1, '已支付')).toBe('Paid')
    expect(copy.statuses.coupon(1, '待使用')).toBe('Available')
    expect(copy.statuses.timelineRemark(2, '商户确认')).toBe('Confirmed by place')
    expect(copy.statuses.timelineRemark(99, '后台备注')).toBe('Unknown status')
  })

  it('localizes known backend errors while preserving trace ids', () => {
    const copy = tradeStringsForRegion('EU')

    expect(localizeWebTradeError(copy, new Error('券码不存在 [traceId: abc-123]'), 'Fallback')).toBe(
      'Voucher not found [traceId: abc-123]',
    )
    expect(localizeWebTradeError(copy, new Error('Unexpected gateway response'), 'Fallback')).toBe(
      'Unexpected gateway response',
    )
  })

  it('formats trade dates for the active locale', () => {
    expect(formatWebTradeDate('2026-08-01', 'zh-CN')).toBe('2026/8/1')
    expect(formatWebTradeDate('2026-08-01', 'en')).toBe('01/08/2026')
  })
})
