import { createApp } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const serviceMocks = vi.hoisted(() => ({ loginAdmin: vi.fn() }))
const sessionMocks = vi.hoisted(() => ({
  state: { region: 'CN' as const },
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
  })

  it('说明数据库 RBAC 授权与服务端实时身份核验，不再展示轻量会话文案', () => {
    const { app, host } = mount()
    const text = host.textContent ?? ''

    expect(text).toContain('数据库 RBAC 授权')
    expect(text).toContain('登录响应会载入管理员资料、权限与区域范围')
    expect(text).toContain('auth/me 实时水合')
    expect(text).toContain('管理员与角色管理')
    expect(text).not.toContain('本地配置管理员')
    expect(text).not.toContain('轻量管理员会话')
    expect(text).not.toContain('不接重 RBAC')
    expect(text).not.toContain('再谈复杂权限体系')

    app.unmount()
  })
})
