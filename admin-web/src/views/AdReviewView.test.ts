import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchAdCampaigns: vi.fn(),
  auditAdCampaign: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['operations:ad:read', 'operations:ad:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import AdReviewView from './AdReviewView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

function campaign(overrides: Record<string, unknown> = {}) {
  return {
    id: 8001, shopId: 10001, shopName: '沪上渝里', name: '火锅推广', slotType: 1,
    slotTypeText: '搜索结果', keyword: '火锅', bidCpc: 2.5, dailyBudget: 100, spentToday: 0,
    totalSpent: 0, status: 1, statusText: '投放中', auditStatus: 1, auditStatusText: '待审核',
    rejectReason: '', createdAt: null, updatedAt: null, ...overrides,
  }
}

function page(list: unknown[]) {
  return { list, total: list.length, page: 1, pageSize: 50, hasMore: false }
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(AdReviewView)
  app.mount(host)
  mountedApps.push(app)
  return { host }
}

describe('AdReviewView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['operations:ad:read', 'operations:ad:write']
    mocks.fetchAdCampaigns.mockImplementation(async () => page([campaign()]))
    mocks.auditAdCampaign.mockImplementation(async () => campaign({ auditStatus: 2 }))
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('lists pending campaigns and approves one', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchAdCampaigns).toHaveBeenCalled()
    expect(host.textContent).toContain('火锅推广')

    host.querySelector<HTMLButtonElement>('[data-testid="approve-8001"]')!.dispatchEvent(new Event('click'))
    await flushView()

    expect(mocks.auditAdCampaign).toHaveBeenCalledWith(8001, { approved: true, rejectReason: undefined })
    expect(host.textContent).toContain('广告已通过。')
  })

  it('hides audit controls without write permission', async () => {
    sessionMock.state.permissions = ['operations:ad:read']
    const { host } = mountView()
    await flushView()

    expect(host.querySelector('[data-testid="approve-8001"]')).toBeNull()
    expect(host.textContent).toContain('你只有广告投放的只读权限。')
  })
})
