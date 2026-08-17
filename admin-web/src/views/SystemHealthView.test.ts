import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  getAdminSystemHealth: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['system:health:read'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import SystemHealthView from './SystemHealthView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const health = {
  status: 'degraded' as const,
  checkedAt: '2026-08-14T13:30:00',
  uptimeSeconds: 93_900,
  runtimeMode: 'pre',
  applicationVersion: '2026.08.14',
  activeProfiles: ['mysql', 'eu'],
  components: [
    {
      key: 'database',
      status: 'up' as const,
      checkType: 'connectivity',
      critical: true,
      latencyMillis: 12,
      detail: 'Connection validated',
    },
    {
      key: 'push',
      status: 'disabled' as const,
      checkType: 'configuration',
      critical: false,
      latencyMillis: 0,
      detail: 'No provider enabled',
    },
  ],
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
  const app = createApp(SystemHealthView)
  app.mount(host)
  mountedApps.push(app)
  return { host }
}

function refreshButton(host: HTMLElement) {
  return [...host.querySelectorAll<HTMLButtonElement>('button')]
    .find((candidate) => candidate.textContent?.trim() === 'Run checks again')
}

describe('SystemHealthView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    adminMocks.getAdminSystemHealth.mockResolvedValue(health)
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('renders health summaries and component checks without exposing configuration values', async () => {
    const { host } = mount()
    await flush()

    expect(adminMocks.getAdminSystemHealth).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('System Health')
    expect(host.textContent).toContain('Degraded')
    expect(host.textContent).toContain('1d 2h')
    expect(host.textContent).toContain('mysql, eu')
    expect(host.textContent).toContain('MySQL database')
    expect(host.textContent).toContain('12 ms')
    expect(host.textContent).toContain('Mobile push')
    expect(host.textContent).toContain('Disabled')
    expect(host.textContent).toContain('No provider enabled')
  })

  it('shows a request error and recovers when checks are run again', async () => {
    adminMocks.getAdminSystemHealth
      .mockRejectedValueOnce(new Error('health endpoint unavailable'))
      .mockResolvedValueOnce(health)
    const { host } = mount()
    await flush()

    expect(host.textContent).toContain('health endpoint unavailable')
    expect(host.textContent).toContain('No component status is available.')

    refreshButton(host)!.click()
    await flush()

    expect(adminMocks.getAdminSystemHealth).toHaveBeenCalledTimes(2)
    expect(host.textContent).not.toContain('health endpoint unavailable')
    expect(host.textContent).toContain('Connection validated')
  })

  it('switches labels when the session region changes', async () => {
    const { host } = mount()
    await flush()

    sessionMock.state.region = 'CN'
    await flush()

    expect(host.textContent).toContain('系统健康')
    expect(host.textContent).toContain('部分降级')
    expect(host.textContent).toContain('1 天 2 小时')
    expect(host.textContent).toContain('MySQL 数据库')
  })
})
