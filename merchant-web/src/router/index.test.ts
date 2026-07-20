import { describe, expect, it, vi } from 'vitest'

const routerMocks = vi.hoisted(() => ({
  beforeEach: vi.fn(),
  afterEach: vi.fn(),
}))
const sessionState = vi.hoisted(() => ({ token: 'expired-token' }))
const serviceMocks = vi.hoisted(() => ({ fetchSettlementStatus: vi.fn() }))

vi.mock('vue-router', () => ({
  createWebHistory: vi.fn(),
  createRouter: vi.fn(() => routerMocks),
}))

vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: sessionState }),
}))

vi.mock('@/services/merchant', () => serviceMocks)

await import('./index')

describe('merchant router guard', () => {
  it('returns to login when settlement check invalidates an expired session', async () => {
    serviceMocks.fetchSettlementStatus.mockImplementation(async () => {
      sessionState.token = ''
      throw new Error('商户登录已失效，请重新登录')
    })
    const guard = routerMocks.beforeEach.mock.calls[0][0]

    const result = await guard({
      path: '/dashboard',
      fullPath: '/dashboard',
      meta: { requiresAuth: true },
    })

    expect(result).toEqual({ path: '/login', query: { redirect: '/dashboard' } })
  })
})
