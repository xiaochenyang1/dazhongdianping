import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const serviceMocks = vi.hoisted(() => ({ registerMerchant: vi.fn() }))
const sessionMocks = vi.hoisted(() => ({ setSession: vi.fn() }))
const routerMocks = vi.hoisted(() => ({ replace: vi.fn() }))

vi.mock('@/services/merchant', () => serviceMocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ setSession: sessionMocks.setSession }),
}))
vi.mock('vue-router', () => ({
  RouterLink: { props: ['to'], template: '<a><slot /></a>' },
  useRouter: () => routerMocks,
}))

import RegisterView from './RegisterView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('RegisterView', () => {
  beforeEach(() => {
    Object.values(serviceMocks).forEach((mock) => mock.mockReset())
    Object.values(sessionMocks).forEach((mock) => mock.mockReset())
    Object.values(routerMocks).forEach((mock) => mock.mockReset())
    serviceMocks.registerMerchant.mockResolvedValue({
      accessToken: 'merchant-token',
      tokenType: 'Bearer',
      merchantId: 77,
      operatorId: 88,
      account: 'owner@example.com',
      auditStatus: 0,
    })
  })

  it('registers the owner, saves the regional session and opens settlement', async () => {
    const host = document.createElement('div')
    const app = createApp(RegisterView)
    app.mount(host)

    const values: Record<string, string> = {
      account: 'owner@example.com',
      password: 'Merchant#123456',
      companyName: 'North Star Foods',
      contactName: 'Alice',
      contactPhone: '+33123456789',
      region: 'EU',
    }
    Object.entries(values).forEach(([name, value]) => {
      const input = host.querySelector<HTMLInputElement | HTMLSelectElement>(`[name="${name}"]`)
      if (!input) throw new Error(`missing ${name}`)
      input.value = value
      input.dispatchEvent(new Event('input'))
      input.dispatchEvent(new Event('change'))
    })

    host.querySelector('form')?.dispatchEvent(new Event('submit'))
    await flushView()

    expect(serviceMocks.registerMerchant).toHaveBeenCalledWith(values)
    expect(sessionMocks.setSession).toHaveBeenCalledWith(expect.objectContaining({
      accessToken: 'merchant-token',
      merchantId: 77,
      account: 'owner@example.com',
      region: 'EU',
    }))
    expect(routerMocks.replace).toHaveBeenCalledWith('/settlement')
    app.unmount()
  })
})
