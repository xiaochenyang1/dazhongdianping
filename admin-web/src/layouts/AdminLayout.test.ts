import { createApp, nextTick, reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => {
  const state = {
    token: 'stale-admin-token' as string | undefined,
    profile: { id: 1, account: 'admin', name: '本地旧身份' },
    permissions: ['system:admin:read'],
    regions: ['EU'],
    region: 'EU',
  }
  return {
    state,
    clearSession: vi.fn(),
    fetchAdminMe: vi.fn(),
    fetchAdminMenus: vi.fn(),
    logoutAdmin: vi.fn(),
    router: { replace: vi.fn() },
    route: { meta: {} as Record<string, unknown>, path: '/dashboard', fullPath: '/dashboard' },
    setRegion: vi.fn(),
    updateIdentity: vi.fn(),
  }
})

vi.mock('@/services/admin', () => ({
  fetchAdminMe: mocks.fetchAdminMe,
  fetchAdminMenus: mocks.fetchAdminMenus,
  logoutAdmin: mocks.logoutAdmin,
}))
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: mocks.state,
    clearSession: mocks.clearSession,
    setRegion: mocks.setRegion,
    updateIdentity: mocks.updateIdentity,
  }),
}))
vi.mock('vue-router', () => ({
  RouterLink: { template: '<a><slot /></a>' },
  RouterView: { template: '<div data-testid="router-view" />' },
  useRoute: () => mocks.route,
  useRouter: () => mocks.router,
}))

import AdminLayout from './AdminLayout.vue'

function deferred<T>() {
  let resolve: (value: T) => void
  const promise = new Promise<T>((resolver) => {
    resolve = resolver
  })
  return { promise, resolve: resolve! }
}

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(AdminLayout)
  app.mount(host)
  return { app, host }
}

describe('AdminLayout', () => {
  beforeEach(() => {
    mocks.state = reactive({
      token: 'stale-admin-token' as string | undefined,
      profile: { id: 1, account: 'admin', name: '本地旧身份' },
      permissions: ['system:admin:read'],
      regions: ['EU'],
      region: 'EU',
    })
    mocks.clearSession.mockReset()
    mocks.fetchAdminMe.mockReset()
    mocks.fetchAdminMenus.mockReset()
    mocks.logoutAdmin.mockReset()
    mocks.router.replace.mockReset()
    mocks.setRegion.mockReset()
    mocks.updateIdentity.mockReset()
    mocks.route = reactive({
      meta: { requiredPermission: 'system:admin:read' },
      path: '/system/admins',
      fullPath: '/system/admins',
    })
    mocks.updateIdentity.mockImplementation((identity) => {
      mocks.state.profile = identity.profile
      mocks.state.permissions = identity.permissions
      mocks.state.regions = identity.regions
    })
    mocks.fetchAdminMenus.mockResolvedValue([])
  })

  it('waits for the server identity before mounting a child route from stale local permissions', async () => {
    const identity = deferred<{
      profile: { id: number; account: string; name: string }
      permissions: string[]
      regions: string[]
    }>()
    mocks.fetchAdminMe.mockReturnValue(identity.promise)
    mocks.router.replace.mockImplementation(async (target: string) => {
      if (target === '/dashboard') {
        mocks.route.path = '/dashboard'
        mocks.route.fullPath = '/dashboard'
        mocks.route.meta = {}
      }
    })

    const { app, host } = mount()
    await nextTick()

    expect(host.querySelector('[data-testid="router-view"]')).toBeNull()
    expect(mocks.fetchAdminMenus).not.toHaveBeenCalled()

    identity.resolve({
      profile: { id: 2, account: 'reviewer', name: '服务端审核员' },
      permissions: ['audit:review:read'],
      regions: ['EU'],
    })
    await flush()

    expect(mocks.updateIdentity).toHaveBeenCalledWith({
      profile: { id: 2, account: 'reviewer', name: '服务端审核员' },
      permissions: ['audit:review:read'],
      regions: ['EU'],
    })
    expect(mocks.router.replace).toHaveBeenCalledWith('/dashboard')
    await flush()
    expect(host.querySelector('[data-testid="router-view"]')).not.toBeNull()

    app.unmount()
  })

  it('re-hydrates server identity before mounting a newly navigated protected route', async () => {
    mocks.route = reactive({ meta: {}, path: '/dashboard', fullPath: '/dashboard' })
    mocks.fetchAdminMe.mockResolvedValueOnce({
      profile: { id: 2, account: 'reviewer', name: '服务端审核员' },
      permissions: ['audit:review:read'],
      regions: ['EU'],
    })
    const downgradedIdentity = deferred<{
      profile: { id: number; account: string; name: string }
      permissions: string[]
      regions: string[]
    }>()
    mocks.fetchAdminMe.mockReturnValueOnce(downgradedIdentity.promise)
    mocks.router.replace.mockResolvedValue(undefined)

    const { app, host } = mount()
    await flush()
    expect(host.querySelector('[data-testid="router-view"]')).not.toBeNull()

    mocks.route.path = '/audit/reviews'
    mocks.route.fullPath = '/audit/reviews'
    mocks.route.meta = { requiredPermission: 'audit:review:read' }
    await nextTick()

    expect(host.querySelector('[data-testid="router-view"]')).toBeNull()
    expect(mocks.fetchAdminMe).toHaveBeenCalledTimes(2)

    downgradedIdentity.resolve({
      profile: { id: 2, account: 'reviewer', name: '服务端审核员' },
      permissions: [],
      regions: ['EU'],
    })
    await flush()

    expect(mocks.router.replace).toHaveBeenCalledWith('/dashboard')
    expect(host.querySelector('[data-testid="router-view"]')).toBeNull()

    app.unmount()
  })

  it('redirects to login when a mounted protected layout loses its token', async () => {
    mocks.route = reactive({
      meta: { requiredPermission: 'audit:review:read' },
      path: '/audit/reviews',
      fullPath: '/audit/reviews',
    })
    mocks.fetchAdminMe.mockResolvedValue({
      profile: { id: 2, account: 'reviewer', name: '服务端审核员' },
      permissions: ['audit:review:read'],
      regions: ['EU'],
    })

    const { app, host } = mount()
    await flush()
    expect(host.querySelector('[data-testid="router-view"]')).not.toBeNull()

    mocks.state.token = undefined
    await flush()

    expect(mocks.router.replace).toHaveBeenCalledWith('/login')
    expect(host.querySelector('[data-testid="router-view"]')).toBeNull()

    app.unmount()
  })

  it('keeps stale menus hidden and loading active while a newer route hydration is pending', async () => {
    mocks.route = reactive({ meta: {}, path: '/dashboard', fullPath: '/dashboard' })
    const auditIdentity = {
      profile: { id: 2, account: 'reviewer', name: '服务端审核员' },
      permissions: ['audit:review:read'],
      regions: ['EU'],
    }
    const auditMenu = [{
      code: 'audit',
      name: '审核中心',
      path: '/audit',
      children: [{ code: 'audit.reviews', name: '点评审核', path: '/audit/reviews', children: [] }],
    }]
    const staleMenuResponse = deferred<typeof auditMenu>()
    const newestIdentity = deferred<typeof auditIdentity>()
    mocks.fetchAdminMe
      .mockResolvedValueOnce(auditIdentity)
      .mockResolvedValueOnce(auditIdentity)
      .mockReturnValueOnce(newestIdentity.promise)
    mocks.fetchAdminMenus
      .mockResolvedValueOnce(auditMenu)
      .mockReturnValueOnce(staleMenuResponse.promise)
      .mockResolvedValueOnce([])

    const { app, host } = mount()
    await flush()
    expect(host.textContent).toContain('点评审核')

    mocks.route.path = '/audit/reviews'
    mocks.route.fullPath = '/audit/reviews'
    mocks.route.meta = { requiredPermission: 'audit:review:read' }
    await flush()
    expect(host.textContent).not.toContain('点评审核')
    expect(host.textContent).toContain('菜单加载中...')

    mocks.route.fullPath = '/audit/reviews?tab=latest'
    await nextTick()
    staleMenuResponse.resolve(auditMenu)
    await flush()

    expect(host.textContent).not.toContain('点评审核')
    expect(host.textContent).toContain('菜单加载中...')

    newestIdentity.resolve(auditIdentity)
    await flush()
    expect(host.textContent).not.toContain('菜单加载中...')

    app.unmount()
  })
})
