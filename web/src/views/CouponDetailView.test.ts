import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const tradeMocks = vi.hoisted(() => ({
  fetchCouponDetail: vi.fn(),
}))

vi.mock('@/services/trade', () => tradeMocks)
vi.mock('vue-router', () => ({
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path"><slot /></a>',
  },
}))

import CouponDetailView from './CouponDetailView.vue'

const inlinePng = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAFElEQVR42mP8z8Dwn4GBgYGJAQoAHxcCAr7afKQAAAAASUVORK5CYII='

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount(code = 'CPABC123') {
  const host = document.createElement('div')
  const app = createApp(CouponDetailView, { code })
  app.mount(host)
  return { app, host }
}

describe('CouponDetailView', () => {
  beforeEach(() => {
    useAppContext().setRegion('CN')
    tradeMocks.fetchCouponDetail.mockReset()
    tradeMocks.fetchCouponDetail.mockResolvedValue({
      id: 11,
      orderId: 88,
      code: 'CPABC123',
      status: 1,
      statusText: '待使用',
      dealId: 40001,
      dealTitle: '双人套餐',
      shopId: 10001,
      shopName: '测试火锅',
      coverImage: 'https://example.com/cover.jpg',
      expireAt: '2026-12-31',
      rules: '周末通用；需提前预约',
      validStart: '2026-07-01',
      validEnd: '2026-12-31',
      usable: true,
      qrPayload: 'CPABC123',
      qrImageUrl: inlinePng,
      verifyHint: '到店后出示二维码或券码，由商户核销。',
    })
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: vi.fn().mockResolvedValue(undefined) },
    })
  })

  it('loads coupon detail with qr image and copy action', async () => {
    const { app, host } = mount()
    await flush()

    expect(tradeMocks.fetchCouponDetail).toHaveBeenCalledWith('CPABC123')
    expect(host.textContent).toContain('双人套餐')
    expect(host.textContent).toContain('CPABC123')
    expect(host.textContent).toContain('到店后出示二维码或券码')
    expect(host.querySelector('[data-testid="coupon-qr-image"]')?.getAttribute('src')).toBe(inlinePng)

    host.querySelector<HTMLButtonElement>('[data-testid="copy-coupon-code"]')?.click()
    await flush()
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('CPABC123')
    expect(host.textContent).toContain('已复制')
    app.unmount()
  })

  it('shows backend error when coupon is missing', async () => {
    tradeMocks.fetchCouponDetail.mockRejectedValueOnce(new Error('券码不存在'))
    const { app, host } = mount('MISSING')
    await flush()
    expect(host.textContent).toContain('券码不存在')
    app.unmount()
  })

  it.each([
    'https://api.qrserver.com/v1/create-qr-code/?data=CPABC123',
    '//example.com/qr?code=CPABC123',
    'data:image/svg+xml;base64,PHN2Zz4=',
    'data:image/png;base64,invalid<',
  ])('keeps manual redemption available without rendering unsafe QR source %s', async (qrImageUrl) => {
    const detail = await tradeMocks.fetchCouponDetail()
    tradeMocks.fetchCouponDetail.mockResolvedValue({ ...detail, qrImageUrl })
    const { app, host } = mount()
    await flush()
    expect(host.querySelector('[data-testid="coupon-qr-image"]')).toBeNull()
    expect(host.textContent).toContain('请出示下方券码')
    host.querySelector<HTMLButtonElement>('[data-testid="copy-coupon-code"]')?.click()
    await flush()
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith('CPABC123')
    app.unmount()
  })

  it('falls back to the voucher code if the embedded PNG cannot be displayed', async () => {
    const { app, host } = mount()
    await flush()
    host.querySelector('[data-testid="coupon-qr-image"]')?.dispatchEvent(new Event('error'))
    await flush()
    expect(host.querySelector('[data-testid="coupon-qr-image"]')).toBeNull()
    expect(host.textContent).toContain('请出示下方券码')
    app.unmount()
  })

  it('does not expose backend Chinese status or verification hints in EU', async () => {
    useAppContext().setRegion('EU')
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('Available')
    expect(host.textContent).toContain('Ready to redeem')
    expect(host.textContent).toContain('Show this QR code or voucher code')
    expect(host.textContent).toContain('31/12/2026')
    expect(host.textContent).not.toContain('待使用')
    expect(host.textContent).not.toContain('到店后出示')
    app.unmount()
  })
})
