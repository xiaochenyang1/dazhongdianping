import { createApp } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const serviceMocks = vi.hoisted(() => ({ loginAdmin: vi.fn() }))
const sessionMocks = vi.hoisted(() => ({
  state: { region: 'CN' as 'CN' | 'EU' },
  setSession: vi.fn(),
  setRegion: vi.fn(),
}))
const routerMocks = vi.hoisted(() => ({ replace: vi.fn() }))

vi.mock('@/services/admin', () => serviceMocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => sessionMocks,
}))
vi.mock('vue-router', () => ({
  useRoute: () => ({ query: { redirect: '/dashboard' } }),
  useRouter: () => routerMocks,
}))

import LoginView from './LoginView.vue'

function mount() {
  const host = document.createElement('div')
  const app = createApp(LoginView)
  app.mount(host)
  return { app, host }
}

describe('LoginView', () => {
  beforeEach(() => {
    Object.values(serviceMocks).forEach((mock) => mock.mockReset())
    Object.values(sessionMocks).filter((value) => typeof value === 'function').forEach((mock) => mock.mockReset())
    Object.values(routerMocks).forEach((mock) => mock.mockReset())
    sessionMocks.state.region = 'CN'
  })

  it('localizes the admin entry copy for the EU region', () => {
    sessionMocks.state.region = 'EU'
    const { app, host } = mount()
    const text = host.textContent ?? ''

    expect(text).toContain('Database-backed RBAC')
    expect(text).toContain('Current region EU')
    expect(text).toContain('Live permissions')
    expect(text).toContain('Admin Accounts')
    expect(text).toContain('Enter console')
    expect(text).not.toContain('本地配置管理员')
    expect(text).not.toContain('轻量管理员会话')

    app.unmount()
  })
})
