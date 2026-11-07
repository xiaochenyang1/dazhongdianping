import { createApp, nextTick, reactive, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({ fetchSeckill: vi.fn(), claimSeckill: vi.fn(), push: vi.fn(), openAuthDialog: vi.fn() }))
vi.mock('@/services/campaign', () => mocks)
vi.mock('vue-router', () => ({
  useRouter: () => ({ push: mocks.push }),
  RouterLink: { props: ['to'], template: '<a :href="to"><slot /></a>' },
}))
const state = reactive({ region: 'EU' })
const session = reactive({ accessToken: 'token', currentUser: { id: 1 } })
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => ({ state }) }))
vi.mock('@/composables/useUserSession', () => ({ useUserSession: () => ({ state: session, openAuthDialog: mocks.openAuthDialog }) }))
import SeckillView from './SeckillView.vue'

const mounted: App[] = []
const event = { id: 12, title: 'Lunch flash sale', dealId: 41, seckillPrice: 9.9, currency: 'EUR', stock: 5, sold: 2, availableStock: 3 }
async function flush() { for (let i = 0; i < 8; i++) await Promise.resolve(); await nextTick() }
function mount() { const host = document.createElement('div'); const app = createApp(SeckillView); mounted.push(app); app.mount(host); return host }
function buy(host: HTMLElement) { return host.querySelector<HTMLButtonElement>('[data-testid="seckill-buy-12"]')! }

describe('flash-sale purchase', () => {
  beforeEach(() => {
    Object.values(mocks).forEach(mock => mock.mockReset())
    state.region = 'EU'; session.accessToken = 'token'; session.currentUser = { id: 1 }
    mocks.fetchSeckill.mockResolvedValue([event])
  })
  afterEach(() => mounted.splice(0).forEach(app => app.unmount()))

  it('shows the price and rules and navigates to the created order once', async () => {
    const host = mount(); await flush()
    expect(host.textContent).toContain('9.9')
    expect(host.textContent).toContain('15 minutes')
    expect(host.textContent).toContain('3 left')
    let finish!: (result: object) => void
    mocks.claimSeckill.mockReturnValue(new Promise(resolve => { finish = resolve }))
    buy(host).click(); buy(host).click(); await flush()
    expect(mocks.claimSeckill).toHaveBeenCalledTimes(1)
    expect(buy(host).disabled).toBe(true)
    finish({ orderId: 87, order: { id: 87 } }); await flush()
    expect(mocks.push).toHaveBeenCalledWith('/user/orders/87')
  })

  it('offers login before reserving inventory', async () => {
    session.accessToken = ''
    const host = mount(); await flush(); buy(host).click(); await flush()
    expect(mocks.openAuthDialog).toHaveBeenCalledWith({ mode: 'password', redirectTo: '/marketing/seckill' })
    expect(mocks.claimSeckill).not.toHaveBeenCalled()
  })

  it('retains access to an existing order even when the event is sold out', async () => {
    mocks.fetchSeckill.mockResolvedValue([{ ...event, availableStock: 0, orderId: 87, participationStatus: 1 }])
    const host = mount(); await flush()
    expect(host.querySelector('a[href="/user/orders/87"]')?.textContent).toBe('View order')
    expect(buy(host)).toBeNull()
  })

  it('disables sold-out events and shows localized purchase errors with retry', async () => {
    mocks.fetchSeckill.mockResolvedValueOnce([{ ...event, availableStock: 0 }])
    const host = mount(); await flush()
    expect(buy(host).disabled).toBe(true)
    session.accessToken = 'refreshed'; await flush()
    mocks.claimSeckill.mockRejectedValue(new Error('秒杀已售罄'))
    buy(host).click(); await flush()
    expect(host.textContent).toContain('This flash sale is sold out.')
    expect(buy(host).disabled).toBe(false)
    expect(mocks.push).not.toHaveBeenCalled()
  })

  it.each(['region', 'account'])('ignores purchase responses after changing %s', async scope => {
    const host = mount(); await flush()
    let finish!: (result: object) => void
    mocks.claimSeckill.mockReturnValue(new Promise(resolve => { finish = resolve }))
    buy(host).click(); await flush()
    mocks.fetchSeckill.mockResolvedValue([])
    if (scope === 'region') state.region = 'CN'
    else session.currentUser = { id: 2 }
    await flush(); finish({ orderId: 87 }); await flush()
    expect(mocks.push).not.toHaveBeenCalled()
    expect(host.textContent).not.toContain('Lunch flash sale')
  })

  it('retries list failures without displaying an empty-state success', async () => {
    mocks.fetchSeckill.mockRejectedValueOnce(new Error('Network unavailable'))
    const host = mount(); await flush()
    expect(host.textContent).toContain('Network unavailable')
    expect(host.textContent).not.toContain('There are no')
    host.querySelector<HTMLButtonElement>('[data-testid="seckill-retry"]')!.click(); await flush()
    expect(host.textContent).toContain('Lunch flash sale')
  })
})
