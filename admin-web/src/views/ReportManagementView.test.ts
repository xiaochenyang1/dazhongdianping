import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAdminReports: vi.fn(),
  resolveAdminReport: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['audit:report:read', 'audit:report:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import ReportManagementView from './ReportManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const reports = {
  list: [
    {
      id: 11,
      reportType: 'review',
      reportTypeText: '点评举报',
      targetId: 101,
      targetTypeText: '',
      reporterUserId: 9,
      reporterUserName: '小明',
      reason: '广告',
      status: 0,
      statusText: '待处理',
      region: 'EU',
      targetSummary: '快来加微信',
      targetAuthorName: '作者A',
      targetStatusText: '公开',
      createdAt: '2026-07-24 12:00:00',
    },
  ],
  total: 1,
  page: 1,
  pageSize: 10,
  hasMore: false,
}

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(ReportManagementView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

describe('ReportManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['audit:report:read', 'audit:report:write']
    adminMocks.listAdminReports.mockResolvedValue(reports)
    adminMocks.resolveAdminReport.mockResolvedValue({ ...reports.list[0], status: 1, statusText: '已成立' })
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads pending reports for current region', async () => {
    const { app, host } = mount()
    await flush()
    expect(adminMocks.listAdminReports).toHaveBeenCalledWith(
      expect.objectContaining({ status: 0, page: 1 }),
    )
    expect(host.textContent).toContain('Content Reports')
    expect(host.textContent).toContain('Review report')
    expect(host.textContent).toContain('广告')
    app.unmount()
  })

  it('resolves selected report as hide', async () => {
    const { app, host } = mount()
    await flush()
    host.querySelector<HTMLButtonElement>('[data-testid="report-hide"]')?.click()
    await flush()
    expect(adminMocks.resolveAdminReport).toHaveBeenCalledWith('review', 11, {
      action: 'hide',
      remark: undefined,
    })
    expect(host.textContent).toContain('Report #11 upheld and content hidden.')
    app.unmount()
  })

  it('keeps report details visible while hiding actions from read-only users', async () => {
    sessionMock.state.permissions = ['audit:report:read']
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('Review report')
    expect(host.textContent).toContain('广告')
    expect(host.textContent).toContain('This account is read-only and cannot process reports.')
    expect(host.querySelector('[data-testid="report-hide"]')).toBeNull()
    expect(host.querySelector('[data-testid="report-dismiss"]')).toBeNull()
    app.unmount()
  })
})
