import { createApp, nextTick, reactive, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchGroupBuy: vi.fn(),
  openGroupTeam: vi.fn(),
  joinGroupTeam: vi.fn(),
  push: vi.fn(),
  openAuthDialog: vi.fn(),
}))
const route = reactive({ query: {} as Record<string, string> })
vi.mock('@/services/campaign', () => mocks)
vi.mock('vue-router', () => ({
  useRouter: () => ({ push: mocks.push }),
  useRoute: () => route,
  RouterLink: { props: ['to'], template: '<a :href="to"><slot /></a>' },
}))
const state = reactive({ region: 'EU' })
const session = reactive({ accessToken: 'token', currentUser: { id: 1 } })
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => ({ state }) }))
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({ state: session, openAuthDialog: mocks.openAuthDialog }),
}))
import GroupBuyView from './GroupBuyView.vue'

const mounted: App[] = []
const campaign = { id: 12, title: 'Dinner group', dealId: 41, groupPrice: 19.9, currency: 'EUR', groupSize: 3 }
async function flush() { for (let i = 0; i < 8; i++) await Promise.resolve(); await nextTick() }
function mount() { const host = document.createElement('div'); const app = createApp(GroupBuyView); mounted.push(app); app.mount(host); return host }

describe('group-buy purchase', () => {
  beforeEach(() => {
    Object.values(mocks).forEach(mock => mock.mockReset())
    state.region = 'EU'
    session.accessToken = 'token'
    session.currentUser = { id: 1 }
    mocks.fetchGroupBuy.mockResolvedValue([campaign])
    route.query = {}
  })
  afterEach(() => mounted.splice(0).forEach(app => app.unmount()))

  it('creates an order when opening a team and navigates to it', async () => {
    mocks.openGroupTeam.mockResolvedValue({ id: 90, orderId: 87 })
    const host = mount(); await flush()
    expect(host.textContent).toContain('refunded automatically')
    host.querySelector<HTMLButtonElement>('[data-testid="group-open-12"]')!.click()
    await flush()
    expect(mocks.openGroupTeam).toHaveBeenCalledWith(12)
    expect(mocks.push).toHaveBeenCalledWith('/user/orders/87')
  })

  it('joins by team id and navigates to the member order', async () => {
    mocks.joinGroupTeam.mockResolvedValue({ id: 90, orderId: 88 })
    const host = mount(); await flush()
    const input = host.querySelector<HTMLInputElement>('[data-testid="group-team-id"]')!
    input.value = '90'
    input.dispatchEvent(new Event('input', { bubbles: true }))
    host.querySelector('form')!.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()
    expect(mocks.joinGroupTeam).toHaveBeenCalledWith(90)
    expect(mocks.push).toHaveBeenCalledWith('/user/orders/88')
  })

  it('prefills a shared team id from the invitation URL', async () => {
    route.query = { teamId: '91' }
    const host = mount(); await flush()
    expect(host.querySelector<HTMLInputElement>('[data-testid="group-team-id"]')?.value).toBe('91')
  })

  it('asks the user to sign in before reserving inventory', async () => {
    session.accessToken = ''
    const host = mount(); await flush()
    host.querySelector<HTMLButtonElement>('[data-testid="group-open-12"]')!.click()
    await flush()
    expect(mocks.openAuthDialog).toHaveBeenCalledWith({ mode: 'password', redirectTo: '/marketing/groupbuy' })
    expect(mocks.openGroupTeam).not.toHaveBeenCalled()
  })
})
