import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ fetchAccount: vi.fn() }))
vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: { token: 'token', region: 'EU', account: 'owner@example.com' }, clearSession: vi.fn(), setRegion: vi.fn() }),
}))
vi.mock('vue-router', () => ({
  RouterLink: { props: ['to'], template: '<a :data-to="to"><slot /></a>' },
  RouterView: {
    props: { permissions: { type: Array, default: () => [] } },
    template: '<div data-testid="router-view">{{ permissions.join(",") }}</div>',
  },
  useRoute: () => ({ path: '/dashboard', meta: { title: '经营概览' } }),
  useRouter: () => ({ replace: vi.fn() }),
}))

import MerchantLayout from './MerchantLayout.vue'

async function render(permissions: string[]) {
  mocks.fetchAccount.mockResolvedValue({ merchant: { id: 7, companyName: 'North Star', region: 'EU' }, operator: { id: 8, type: 'owner', name: 'Alice' }, permissions })
  const host = document.createElement('div')
  const app = createApp(MerchantLayout)
  app.mount(host)
  await Promise.resolve()
  await nextTick()
  return { app, host }
}

describe('MerchantLayout', () => {
  beforeEach(() => mocks.fetchAccount.mockReset())

  it('only exposes staff management with staff:manage permission', async () => {
    const without = await render(['coupon:verify'])
    expect(without.host.textContent).not.toContain('员工管理')
    expect(without.host.textContent).toContain('券码核销')
    without.app.unmount()

    const owner = await render(['staff:manage'])
    expect(owner.host.textContent).toContain('员工管理')
    owner.app.unmount()
  })

  it('filters navigation by read permissions and passes permissions to the routed view', async () => {
    const { app, host } = await render(['shop:view', 'reservation:view', 'review:reply', 'coupon:verify'])
    const paths = [...host.querySelectorAll('a')].map((link) => link.getAttribute('data-to'))

    expect(paths).toEqual(['/shops', '/reservations', '/coupons', '/reviews'])
    expect(host.querySelector('[data-testid="router-view"]')?.textContent)
      .toBe('shop:view,reservation:view,review:reply,coupon:verify')
    app.unmount()
  })
})
