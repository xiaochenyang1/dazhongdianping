import { createApp, nextTick, reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listImportBatches: vi.fn(),
  listShops: vi.fn(),
  getAdminDashboardOverview: vi.fn(),
  state: {
    region: 'EU',
    permissions: ['audit:review:read'] as string[],
  },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: mocks.state,
  }),
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

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((complete) => {
    resolve = complete
  })
  return { promise, resolve }
}

function shop(id: number, name: string) {
  return {
    id,
    name,
    cityName: '测试市',
    areaName: '测试区',
    categoryName: '测试分类',
    openNow: true,
    createdAt: '2026-07-18 10:00:00',
  }
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(DashboardView)
  app.mount(host)
  return { app, host }
}

describe('DashboardView', () => {
  beforeEach(() => {
    mocks.listImportBatches.mockReset()
    mocks.listShops.mockReset()
    mocks.getAdminDashboardOverview.mockReset()
    mocks.state = reactive({
      region: 'EU',
      permissions: ['audit:review:read'] as string[],
    })
  })

  it('does not request or display data modules unavailable to a review-only administrator', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listShops).not.toHaveBeenCalled()
    expect(mocks.listImportBatches).not.toHaveBeenCalled()
    expect(mocks.getAdminDashboardOverview).not.toHaveBeenCalled()
    expect(host.textContent).not.toContain('Shops in region')
    expect(host.textContent).not.toContain('Import batches')
    expect(host.textContent).not.toContain('Manage shops')
    expect(host.textContent).not.toContain('Run imports')

    app.unmount()
  })

  it('loads and displays each dashboard module granted to a data administrator', async () => {
    mocks.state.permissions = [
      'dashboard:read',
      'data:shop:read',
      'data:import_batch:read',
      'data:shop:import',
      'data:order:read',
      'system:user:read',
      'audit:deal:read',
      'audit:shop_change:read',
    ]
    mocks.listShops.mockResolvedValue({ list: [], total: 3 })
    mocks.listImportBatches.mockResolvedValue({ list: [], total: 2 })
    mocks.getAdminDashboardOverview.mockResolvedValue({
      region: 'EU',
      shopCount: 3,
      importBatchCount: 2,
      paidOrderCount: 8,
      pendingRefundCount: 1,
      pendingAuditTaskCount: 4,
      userCount: 20,
      pendingAuditBreakdown: [
        { bizType: 2, label: '团购审核', count: 4 },
        { bizType: 5, label: '门店草稿审核', count: 2 },
      ],
    })

    const { app, host } = mount()
    await flush()

    expect(mocks.listShops).toHaveBeenCalledWith({ region: 'EU', page: 1, pageSize: 5 })
    expect(mocks.listImportBatches).toHaveBeenCalledWith({ region: 'EU', page: 1, pageSize: 5 })
    expect(mocks.getAdminDashboardOverview).toHaveBeenCalled()
    expect(host.textContent).toContain('Shops in region')
    expect(host.textContent).toContain('Import batches')
    expect(host.textContent).toContain('Paid orders')
    expect(host.textContent).toContain('Pending refunds')
    expect(host.textContent).toContain('Pending audits')
    expect(host.textContent).toContain('Deal audit')
    expect(host.textContent).toContain('Pending deals')
    expect(host.textContent).toContain('Pending shop drafts')
    expect(host.textContent).toContain('Manage shops')
    expect(host.textContent).toContain('Run imports')
    expect(host.querySelectorAll('[data-testid="dashboard-quick-link"]').length).toBeGreaterThanOrEqual(3)
    const breakdownLinks = [...host.querySelectorAll('[data-testid="dashboard-audit-breakdown-link"]')]
    expect(breakdownLinks.length).toBeGreaterThanOrEqual(2)
    expect(breakdownLinks.some((link) => (link as HTMLElement).dataset.to === '/audit/deals')).toBe(true)

    app.unmount()
  })

  it('does not let an older EU snapshot overwrite the newer CN snapshot', async () => {
    mocks.state.permissions = ['data:shop:read']
    const euSnapshot = deferred<{ list: ReturnType<typeof shop>[]; total: number }>()
    const cnSnapshot = deferred<{ list: ReturnType<typeof shop>[]; total: number }>()
    mocks.listShops.mockReturnValueOnce(euSnapshot.promise).mockReturnValueOnce(cnSnapshot.promise)

    const { app, host } = mount()
    await flush()

    expect(mocks.listShops).toHaveBeenLastCalledWith({ region: 'EU', page: 1, pageSize: 5 })

    mocks.state.region = 'CN'
    await flush()

    expect(mocks.listShops).toHaveBeenLastCalledWith({ region: 'CN', page: 1, pageSize: 5 })

    cnSnapshot.resolve({ list: [shop(2, 'CN 门店')], total: 1 })
    await flush()

    expect(host.textContent).toContain('CN 门店')

    euSnapshot.resolve({ list: [shop(1, 'EU 门店')], total: 1 })
    await flush()

    expect(host.textContent).toContain('CN 门店')
    expect(host.textContent).not.toContain('EU 门店')

    app.unmount()
  })

  it('does not restore data from an in-flight request after dashboard permissions are revoked', async () => {
    mocks.state.permissions = ['data:shop:read']
    const oldSnapshot = deferred<{ list: ReturnType<typeof shop>[]; total: number }>()
    const reloadSnapshot = deferred<{ list: ReturnType<typeof shop>[]; total: number }>()
    mocks.listShops.mockReturnValueOnce(oldSnapshot.promise).mockReturnValueOnce(reloadSnapshot.promise)

    const { app, host } = mount()
    await flush()

    mocks.state.permissions = []
    await flush()

    oldSnapshot.resolve({ list: [shop(1, 'EU 门店')], total: 1 })
    await flush()

    mocks.state.permissions = ['data:shop:read']
    await flush()

    expect(mocks.listShops).toHaveBeenCalledTimes(2)
    expect(host.textContent).not.toContain('EU 门店')

    app.unmount()
  })
})
