import { createApp, nextTick } from 'vue'
import { describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ fetchAccount: vi.fn(), fetchDashboard: vi.fn() }))
vi.mock('@/services/merchant', () => mocks)

import DashboardView from './DashboardView.vue'

describe('DashboardView', () => {
  it('renders the typed merchant profile returned by account/me', async () => {
    mocks.fetchAccount.mockResolvedValue({
      merchant: { id: 7, companyName: 'North Star Foods', region: 'EU' },
      operator: { id: 8, type: 'owner', name: 'Alice' },
      permissions: ['staff:manage'],
    })
    mocks.fetchDashboard.mockResolvedValue({ viewCount: 12, paidOrderCount: 3, verifiedCouponCount: 2, reviewCount: 9 })
    const host = document.createElement('div')
    const app = createApp(DashboardView)
    app.mount(host)
    await Promise.resolve()
    await Promise.resolve()
    await nextTick()
    expect(host.textContent).toContain('North Star Foods')
    app.unmount()
  })
})
