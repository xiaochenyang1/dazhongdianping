import { createApp, nextTick, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
const mocks = vi.hoisted(() => ({ fetchConsultSessions: vi.fn() }))
vi.mock('@/services/consult', () => mocks)
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => ({ state: { region: 'EU' } }) }))
vi.mock('vue-router', () => ({ RouterLink: { props: ['to'], template: '<a><slot /></a>' } }))
import ConsultSessionsView from './ConsultSessionsView.vue'
const mounted: App[] = []
const page = (id: number, more = false) => ({ list: [{ id, shopName: `Shop ${id}`, lastMessage: 'Hello', unread: 1 }], hasMore: more, nextBeforeId: more ? id : null, nextBeforeUpdatedAt: more ? '2026-11-06T10:00:00' : null })
async function flush() { await Promise.resolve(); await nextTick(); await Promise.resolve(); await nextTick() }
function mount() { const host = document.createElement('div'); const app = createApp(ConsultSessionsView); mounted.push(app); app.mount(host); return host }
describe('ConsultSessionsView', () => {
  beforeEach(() => mocks.fetchConsultSessions.mockReset())
  afterEach(() => mounted.splice(0).forEach(app => app.unmount()))
  it('keeps the current page on failure and retries the same cursor, then goes back', async () => {
    mocks.fetchConsultSessions.mockResolvedValueOnce(page(20, true))
    const host = mount(); await flush()
    mocks.fetchConsultSessions.mockRejectedValueOnce(new Error('offline'))
    host.querySelector<HTMLButtonElement>('[data-testid="sessions-next"]')!.click(); await flush()
    expect(host.textContent).toContain('Shop 20'); expect(host.textContent).toContain('offline')
    mocks.fetchConsultSessions.mockResolvedValueOnce(page(10))
    host.querySelector<HTMLButtonElement>('[data-testid="sessions-next"]')!.click(); await flush()
    expect(mocks.fetchConsultSessions).toHaveBeenLastCalledWith({ beforeId: 20, beforeUpdatedAt: '2026-11-06T10:00:00', unreadOnly: false })
    expect(host.textContent).toContain('Shop 10'); expect(host.textContent).not.toContain('Shop 20')
    expect(host.querySelector<HTMLButtonElement>('[data-testid="sessions-next"]')!.disabled).toBe(true)
    mocks.fetchConsultSessions.mockResolvedValueOnce(page(20, true))
    host.querySelector<HTMLButtonElement>('[data-testid="sessions-previous"]')!.click(); await flush()
    expect(mocks.fetchConsultSessions).toHaveBeenLastCalledWith({ unreadOnly: false })
  })
  it('resets pagination when filtering and ignores the old response', async () => {
    mocks.fetchConsultSessions.mockResolvedValueOnce(page(20, true))
    const host = mount(); await flush()
    let finish!: (value: unknown) => void
    mocks.fetchConsultSessions.mockReturnValueOnce(new Promise(resolve => { finish = resolve }))
    host.querySelector<HTMLButtonElement>('[data-testid="sessions-next"]')!.click(); await flush()
    mocks.fetchConsultSessions.mockResolvedValueOnce({ ...page(1), list: [] })
    const filter = host.querySelector<HTMLInputElement>('[data-testid="sessions-unread"]')!; filter.checked = true; filter.dispatchEvent(new Event('change')); await flush()
    expect(mocks.fetchConsultSessions).toHaveBeenLastCalledWith({ unreadOnly: true })
    finish(page(10)); await flush()
    expect(host.textContent).toContain('No unread chats.'); expect(host.textContent).not.toContain('Shop 10')
    expect(host.querySelector<HTMLButtonElement>('[data-testid="sessions-previous"]')!.disabled).toBe(true)
  })
})
