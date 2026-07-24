import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  verifyCoupon: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)

import CouponsView from './CouponsView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount(permissions = ['coupon:verify']) {
  const host = document.createElement('div')
  const app = createApp(CouponsView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('CouponsView', () => {
  beforeEach(() => {
    mocks.verifyCoupon.mockReset()
  })

  it('verifies a coupon code and shows the result', async () => {
    mocks.verifyCoupon.mockResolvedValue({
      id: 11,
      code: 'VERIFYME001',
      dealId: 41001,
      dealTitle: '双人套餐',
      shopId: 20001,
      shopName: '巴黎川味馆',
      status: 2,
      statusText: '已使用',
      verifyAt: '2026-07-24 16:20:00',
      expireAt: '2026-12-31',
    })
    const { app, host } = mount()

    const input = host.querySelector<HTMLInputElement>('[data-testid="coupon-code-input"]')
    if (!input) throw new Error('missing coupon input')
    input.value = ' VERIFYME001 '
    input.dispatchEvent(new Event('input', { bubbles: true }))
    await nextTick()
    const form = host.querySelector('form')
    if (!form) throw new Error('missing verify form')
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.verifyCoupon).toHaveBeenCalledWith('VERIFYME001')
    expect(host.textContent).toContain('券码 VERIFYME001 已核销成功')
    expect(host.textContent).toContain('双人套餐')
    expect(host.textContent).toContain('巴黎川味馆')
    expect(host.textContent).toContain('已使用')
    app.unmount()
  })

  it('requires a non-empty code and permission', async () => {
    const denied = mount([])
    expect(denied.host.textContent).toContain('coupon:verify')
    denied.host.querySelector('form')?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()
    expect(mocks.verifyCoupon).not.toHaveBeenCalled()
    denied.app.unmount()

    const { app, host } = mount()
    host.querySelector('form')?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()
    expect(host.textContent).toContain('请输入券码')
    expect(mocks.verifyCoupon).not.toHaveBeenCalled()
    app.unmount()
  })
})
