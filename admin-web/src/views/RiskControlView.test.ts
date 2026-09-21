import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchRiskEvents: vi.fn(),
  disposeRiskEvent: vi.fn(),
  fetchRiskRules: vi.fn(),
  updateRiskRule: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['risk:event:read', 'risk:event:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import RiskControlView from './RiskControlView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

function eventPage() {
  return {
    list: [
      {
        id: 1,
        region: 'CN',
        scene: 'review_create',
        userId: 100,
        deviceFingerprint: 'dev-1',
        ip: '10.0.0.1',
        bizId: null,
        riskScore: 60,
        decision: 3,
        hitRules: 'review_duplicate',
        reason: '相似度过高',
        disposeStatus: 0,
        disposeRemark: '',
        disposedBy: null,
        disposedAt: null,
        createdAt: '2026-09-21 10:00:00',
      },
    ],
    total: 1,
    page: 1,
    pageSize: 50,
    hasMore: false,
  }
}

async function flushView() {
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(RiskControlView)
  app.mount(host)
  mountedApps.push(app)
  return { host }
}

describe('RiskControlView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['risk:event:read', 'risk:event:write']
    mocks.fetchRiskEvents.mockImplementation(async () => eventPage())
    mocks.disposeRiskEvent.mockImplementation(async () => eventPage().list[0])
    mocks.fetchRiskRules.mockImplementation(async () => [])
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads risk events on mount and renders a row', async () => {
    const { host } = mountView()
    await flushView()

    expect(mocks.fetchRiskEvents).toHaveBeenCalled()
    expect(host.textContent).toContain('review_duplicate')
    expect(host.querySelectorAll('tbody tr').length).toBe(1)
  })

  it('disposes an event when the writer confirms risk', async () => {
    const { host } = mountView()
    await flushView()

    const confirmButton = Array.from(host.querySelectorAll('button'))
      .find((btn) => btn.textContent?.includes('确认风险'))
    expect(confirmButton).toBeTruthy()
    confirmButton?.dispatchEvent(new Event('click'))
    await flushView()

    expect(mocks.disposeRiskEvent).toHaveBeenCalledWith(1, expect.objectContaining({ disposeStatus: 1 }))
  })
})
