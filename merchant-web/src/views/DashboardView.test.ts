import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ fetchAccount: vi.fn(), fetchDashboard: vi.fn() }))
const sessionState = vi.hoisted(() => ({ region: 'EU' }))
vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))
vi.mock('vue-router', () => ({
  RouterLink: { props: ['to'], template: '<a :data-to="to"><slot /></a>' },
}))

import DashboardView from './DashboardView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('DashboardView', () => {
  beforeEach(() => {
    mocks.fetchAccount.mockReset()
    mocks.fetchDashboard.mockReset()
  })

  it('renders metrics, todos and permission-aware quick links', async () => {
    mocks.fetchAccount.mockResolvedValue({
      merchant: { id: 7, companyName: 'North Star Foods', region: 'EU' },
      operator: { id: 8, type: 'owner', name: 'Alice' },
      permissions: [
        'dashboard:view',
        'reservation:view',
        'order:view',
        'coupon:verify',
        'deal:edit',
        'shop:edit',
        'staff:manage',
      ],
    })
    mocks.fetchDashboard.mockResolvedValue({
      dateFrom: '2026-07-18',
      dateTo: '2026-07-24',
      views: 12,
      paidOrders: 3,
      paidAmount: 188.5,
      verifiedCoupons: 2,
      pendingRefunds: 4,
      pendingDeals: 3,
      rejectedDeals: 1,
      pendingShopChanges: 2,
      rejectedShopChanges: 5,
      reservations: {
        total: 5,
        pending: 2,
        confirmed: 1,
        arrived: 1,
        rejected: 0,
        noShow: 1,
      },
      rating: { score: 4.6, reviewCount: 9 },
      trend: [],
    })

    const host = document.createElement('div')
    const app = createApp(DashboardView)
    app.mount(host)
    await flush()

    expect(host.textContent).toContain('North Star Foods')
    expect(host.textContent).toContain('Paid amount')
    expect(host.textContent).toContain('188.5')
    expect(host.textContent).toContain('Pending reservations')
    expect(host.textContent).toContain('Pending refunds')
    expect(host.textContent).toContain('Pending deals')
    expect(host.textContent).toContain('Rejected shop drafts')
    expect(host.textContent).toContain('4')
    expect(host.textContent).toContain('To-dos & status')
    expect(host.textContent).toContain('Coupon Verification')
    expect(host.textContent).toContain('Deals')
    expect(host.querySelectorAll('[data-testid="merchant-todo-card"]').length).toBeGreaterThanOrEqual(5)
    expect(host.querySelectorAll('[data-testid="merchant-quick-link"]').length).toBeGreaterThanOrEqual(4)

    app.unmount()
  })
})
