import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  verifyCoupon: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ region: 'EU' }))
const camera = vi.hoisted(() => ({
  start: vi.fn(), stop: vi.fn(),
  payload: null as ((payload: string) => void) | null,
  error: null as ((cause: unknown) => void) | null,
}))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))
vi.mock('@/core/coupon_camera_scanner', async (importOriginal) => {
  const original = await importOriginal<typeof import('@/core/coupon_camera_scanner')>()
  return {
    ...original,
    CouponCameraScanner: class {
      constructor(_video: HTMLVideoElement, payload: (payload: string) => void, error: (cause: unknown) => void) {
        camera.payload = payload
        camera.error = error
      }
      start = camera.start
      stop = camera.stop
    },
  }
})

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
    camera.start.mockReset().mockResolvedValue(undefined)
    camera.stop.mockReset()
    camera.payload = null
    camera.error = null
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
    expect(host.textContent).toContain('Coupon VERIFYME001 verified successfully.')
    expect(host.textContent).toContain('双人套餐')
    expect(host.textContent).toContain('巴黎川味馆')
    expect(host.textContent).toContain('Used')
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
    expect(host.textContent).toContain('Enter a coupon code.')
    expect(mocks.verifyCoupon).not.toHaveBeenCalled()
    app.unmount()
  })

  it('fills a detected coupon for explicit confirmation and blocks duplicate submits while verifying', async () => {
    let complete!: (coupon: object) => void
    mocks.verifyCoupon.mockImplementation(() => new Promise((resolve) => { complete = resolve }))
    const { app, host } = mount()
    host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-start"]')!.click()
    await flush()
    expect(camera.start).toHaveBeenCalledOnce()
    camera.payload!(' CPQRACCEPTANCE001 ')
    await flush()
    expect(host.querySelector<HTMLInputElement>('[data-testid="coupon-code-input"]')!.value).toBe('CPQRACCEPTANCE001')
    expect(host.querySelector('[data-testid="coupon-camera-panel"]')).toBeNull()
    expect(camera.stop).toHaveBeenCalledOnce()
    expect(mocks.verifyCoupon).not.toHaveBeenCalled()
    expect(host.textContent).toContain('Coupon code detected. Confirm to verify it.')
    const form = host.querySelector('form')!
    form.dispatchEvent(new Event('submit', { cancelable: true }))
    form.dispatchEvent(new Event('submit', { cancelable: true }))
    await flush()
    expect(mocks.verifyCoupon).toHaveBeenCalledOnce()
    complete({ id: 1, code: 'CPQRACCEPTANCE001', dealId: 41001, shopId: 20001, status: 2 })
    await flush()
    expect(host.textContent).toContain('Coupon CPQRACCEPTANCE001 verified successfully.')
    app.unmount()
  })

  it('rejects unrelated QR content without changing or submitting the coupon code', async () => {
    const { app, host } = mount()
    const input = host.querySelector<HTMLInputElement>('[data-testid="coupon-code-input"]')!
    input.value = 'KEEP001'
    input.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-start"]')!.click()
    await flush()
    camera.payload!('https://example.invalid/CP001')
    await flush()
    expect(host.textContent).toContain('This QR code is not a valid coupon code.')
    expect(input.value).toBe('KEEP001')
    expect(mocks.verifyCoupon).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="coupon-camera-panel"]')).toBeNull()
    app.unmount()
  })

  it('keeps manual verification available after camera permission is denied', async () => {
    camera.start.mockRejectedValue(Object.assign(new Error('synthetic denial'), { name: 'NotAllowedError' }))
    mocks.verifyCoupon.mockResolvedValue({ id: 2, code: 'MANUAL001', dealId: 41001, shopId: 20001, status: 2 })
    const { app, host } = mount()
    host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-start"]')!.click()
    await flush()
    expect(host.textContent).toContain('Camera permission was denied.')
    const input = host.querySelector<HTMLInputElement>('[data-testid="coupon-code-input"]')!
    expect(input.disabled).toBe(false)
    input.value = 'MANUAL001'
    input.dispatchEvent(new Event('input'))
    host.querySelector('form')!.dispatchEvent(new Event('submit', { cancelable: true }))
    await flush()
    expect(mocks.verifyCoupon).toHaveBeenCalledWith('MANUAL001')
    app.unmount()
  })

  it('closes scanning on navigation and when a pending camera request is cancelled', async () => {
    let granted!: () => void
    camera.start.mockImplementation(() => new Promise<void>((resolve) => { granted = resolve }))
    const first = mount()
    first.host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-start"]')!.click()
    await flush()
    first.host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-stop"]')!.click()
    granted()
    await flush()
    expect(first.host.querySelector('[data-testid="coupon-camera-panel"]')).toBeNull()
    expect(camera.stop).toHaveBeenCalledOnce()
    first.app.unmount()
    camera.start.mockResolvedValue(undefined)
    const second = mount()
    second.host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-start"]')!.click()
    await flush()
    window.dispatchEvent(new Event('pagehide'))
    await flush()
    expect(second.host.querySelector('[data-testid="coupon-camera-panel"]')).toBeNull()
    second.host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-start"]')!.click()
    await flush()
    second.app.unmount()
    expect(camera.stop).toHaveBeenCalledTimes(3)
  })

  it('does not request camera access without verification permission', async () => {
    const { app, host } = mount([])
    const scan = host.querySelector<HTMLButtonElement>('[data-testid="coupon-scan-start"]')!
    expect(scan.disabled).toBe(true)
    scan.click()
    await flush()
    expect(camera.start).not.toHaveBeenCalled()
    app.unmount()
  })
})
