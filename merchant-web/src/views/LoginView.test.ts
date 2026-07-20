import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const serviceMocks = vi.hoisted(() => ({ loginMerchant: vi.fn(), fetchSettlementStatus: vi.fn() }))
const sessionMocks = vi.hoisted(() => ({ setSession: vi.fn(), setRegion: vi.fn() }))
const routerMocks = vi.hoisted(() => ({ replace: vi.fn() }))

vi.mock('@/services/merchant', () => serviceMocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ setSession: sessionMocks.setSession, setRegion: sessionMocks.setRegion }),
}))
vi.mock('vue-router', () => ({
  RouterLink: { props: ['to'], template: '<a><slot /></a>' },
  useRoute: () => ({ query: { redirect: '/orders' } }),
  useRouter: () => routerMocks,
}))

import LoginView from './LoginView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

async function submitLogin() {
  const host = document.createElement('div')
  const app = createApp(LoginView)
  app.mount(host)
  const inputs = host.querySelectorAll<HTMLInputElement>('input')
  inputs[0].value = 'owner@example.com'
  inputs[0].dispatchEvent(new Event('input'))
  inputs[1].value = 'Merchant#123456'
  inputs[1].dispatchEvent(new Event('input'))
  const region = host.querySelector<HTMLSelectElement>('[name="region"]')
  if (!region) throw new Error('missing region')
  region.value = 'EU'
  region.dispatchEvent(new Event('change'))
  host.querySelector('form')?.dispatchEvent(new Event('submit'))
  await flushView()
  return app
}

describe('LoginView', () => {
  beforeEach(() => {
    Object.values(serviceMocks).forEach((mock) => mock.mockReset())
    Object.values(sessionMocks).forEach((mock) => mock.mockReset())
    Object.values(routerMocks).forEach((mock) => mock.mockReset())
    serviceMocks.loginMerchant.mockResolvedValue({ accessToken: 'token', tokenType: 'Bearer', merchantId: 7, account: 'owner@example.com' })
  })

  it('routes a pending merchant to settlement', async () => {
    serviceMocks.fetchSettlementStatus.mockResolvedValue({ status: 0 })
    const app = await submitLogin()
    expect(sessionMocks.setRegion).toHaveBeenCalledWith('EU')
    expect(serviceMocks.fetchSettlementStatus).toHaveBeenCalled()
    expect(routerMocks.replace).toHaveBeenCalledWith('/settlement')
    app.unmount()
  })

  it('restores the requested page for an approved merchant', async () => {
    serviceMocks.fetchSettlementStatus.mockResolvedValue({ status: 1 })
    const app = await submitLogin()
    expect(serviceMocks.fetchSettlementStatus).toHaveBeenCalled()
    expect(routerMocks.replace).toHaveBeenCalledWith('/orders')
    app.unmount()
  })
})
