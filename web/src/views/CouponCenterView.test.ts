import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const sessionState = vi.hoisted(() => ({ accessToken: 'token-123' as string }))
const sessionMocks = vi.hoisted(() => ({ openAuthDialog: vi.fn() }))
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({ state: sessionState, openAuthDialog: sessionMocks.openAuthDialog }),
}))

const appState = vi.hoisted(() => ({ region: 'CN' as 'CN' | 'EU' }))
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: appState }),
}))

const marketingMocks = vi.hoisted(() => ({
  fetchCouponCenter: vi.fn(),
  claimCoupon: vi.fn(),
}))
vi.mock('@/services/marketing', () => marketingMocks)

vi.mock('vue-router', () => ({
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path" v-bind="$attrs"><slot /></a>',
  },
}))

import CouponCenterView from './CouponCenterView.vue'

async function flush() {
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(CouponCenterView)
  app.mount(host)
  return { app, host }
}

describe('CouponCenterView', () => {
  beforeEach(() => {
    appState.region = 'CN'
    sessionState.accessToken = 'token-123'
    marketingMocks.fetchCouponCenter.mockReset()
    marketingMocks.claimCoupon.mockReset()
    sessionMocks.openAuthDialog.mockReset()
    marketingMocks.fetchCouponCenter.mockResolvedValue([
      {
        templateId: 5001,
        name: '满100减20',
        type: 1,
        typeText: '满减券',
        thresholdAmount: 100,
        discountAmount: 20,
        currency: 'CNY',
        shopId: 0,
        perUserLimit: 1,
        validDays: 30,
        claimed: false,
        soldOut: false,
        claimable: true,
      },
    ])
  })

  it('lists claimable coupons and claims one', async () => {
    marketingMocks.claimCoupon.mockResolvedValue({ id: 1 })
    const { app, host } = mount()
    await flush()

    expect(marketingMocks.fetchCouponCenter).toHaveBeenCalled()
    expect(host.textContent).toContain('满100减20')

    const button = host.querySelector('[data-testid="coupon-center-claim-5001"]') as HTMLButtonElement | null
    button?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flush()

    expect(marketingMocks.claimCoupon).toHaveBeenCalledWith(5001)
    expect(host.querySelector('[data-testid="coupon-center-feedback"]')?.textContent).toContain('已领取')
    app.unmount()
  })

  it('prompts login when claiming without a session', async () => {
    sessionState.accessToken = ''
    const { app, host } = mount()
    await flush()

    const button = host.querySelector('[data-testid="coupon-center-claim-5001"]') as HTMLButtonElement | null
    button?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flush()

    expect(sessionMocks.openAuthDialog).toHaveBeenCalled()
    expect(marketingMocks.claimCoupon).not.toHaveBeenCalled()
    app.unmount()
  })
})
