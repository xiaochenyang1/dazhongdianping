import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAdminPointsExchanges: vi.fn(),
  fulfillAdminPointsExchange: vi.fn(),
  cancelAdminPointsExchange: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['operations:points:read', 'operations:points:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import PointsExchangeManagementView from './PointsExchangeManagementView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []

const exchanges = [
  {
    id: 91,
    userId: 7,
    userNickname: 'Nora',
    productId: 1,
    productName: 'Coffee voucher',
    region: 'EU',
    pointsCost: 200,
    quantity: 1,
    status: 0,
    statusText: 'Pending',
    redeemCode: '',
    remark: '',
    fulfilledAt: '',
    createdAt: '2026-07-20 09:00:00',
  },
  {
    id: 92,
    userId: 8,
    userNickname: 'Ivan',
    productId: 2,
    productName: 'Tote bag',
    region: 'EU',
    pointsCost: 800,
    quantity: 1,
    status: 1,
    statusText: 'Fulfilled',
    redeemCode: 'TOTE-2026',
    remark: 'shipped',
    fulfilledAt: '2026-07-21 12:00:00',
    createdAt: '2026-07-20 10:00:00',
  },
]

function pageOf(list: typeof exchanges, hasMore = false) {
  return { list, total: list.length, page: 1, pageSize: 10, hasMore }
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
  const app = createApp(PointsExchangeManagementView)
  app.mount(host)
  mountedApps.push(app)
  return { app, host }
}

function typeInto(host: HTMLElement, testId: string, value: string) {
  const element = host.querySelector<HTMLInputElement>(`[data-testid="${testId}"]`)
  if (!element) throw new Error(`missing input: ${testId}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

describe('PointsExchangeManagementView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['operations:points:read', 'operations:points:write']
    adminMocks.listAdminPointsExchanges.mockResolvedValue(pageOf(exchanges))
    adminMocks.fulfillAdminPointsExchange.mockResolvedValue({
      ...exchanges[0],
      status: 1,
      statusText: 'Fulfilled',
      redeemCode: 'COFFEE-1',
    })
    adminMocks.cancelAdminPointsExchange.mockResolvedValue({
      ...exchanges[0],
      status: 2,
      statusText: 'Cancelled',
    })
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
  })

  it('loads pending redemptions by default', async () => {
    const { app, host } = mount()
    await flush()

    expect(adminMocks.listAdminPointsExchanges).toHaveBeenCalledWith({
      status: 0,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('Coffee voucher')
    expect(host.textContent).toContain('Nora')
    expect(host.textContent).toContain('TOTE-2026')
    app.unmount()
  })

  it('applies status and keyword filters', async () => {
    const { app, host } = mount()
    await flush()

    const statusFilter = host.querySelector<HTMLSelectElement>('[data-testid="exchange-status-filter"]')
    if (!statusFilter) throw new Error('missing status filter')
    statusFilter.value = ''
    statusFilter.dispatchEvent(new Event('change'))
    await flush()

    expect(adminMocks.listAdminPointsExchanges).toHaveBeenLastCalledWith({
      status: undefined,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })

    typeInto(host, 'exchange-keyword-filter', ' Nora ')
    host.querySelectorAll<HTMLButtonElement>('.toolbar button')[0]?.click()
    await flush()

    expect(adminMocks.listAdminPointsExchanges).toHaveBeenLastCalledWith({
      status: undefined,
      keyword: 'Nora',
      page: 1,
      pageSize: 10,
    })
    app.unmount()
  })

  it('fulfills the selected redemption with a manual redeem code', async () => {
    const { app, host } = mount()
    await flush()

    typeInto(host, 'exchange-redeem-code', ' COFFEE-1 ')
    typeInto(host, 'exchange-remark', ' handed over ')
    host.querySelector<HTMLButtonElement>('[data-testid="exchange-fulfill"]')?.click()
    await flush()

    expect(adminMocks.fulfillAdminPointsExchange).toHaveBeenCalledWith(91, {
      redeemCode: 'COFFEE-1',
      remark: 'handed over',
    })
    expect(host.textContent).toContain('COFFEE-1')
    app.unmount()
  })

  it('cancels a redemption after confirmation and reports the refund', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="exchange-cancel"]')?.click()
    await flush()

    expect(confirm).toHaveBeenCalledWith(expect.stringContaining('200 points'))
    expect(adminMocks.cancelAdminPointsExchange).toHaveBeenCalledWith(91, { remark: undefined })
    expect(host.textContent).toContain('200 points refunded')
    app.unmount()
  })

  it('keeps the redemption untouched when the confirmation is dismissed', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="exchange-cancel"]')?.click()
    await flush()

    expect(adminMocks.cancelAdminPointsExchange).not.toHaveBeenCalled()
    app.unmount()
  })

  it('hides actions for processed redemptions and read-only accounts', async () => {
    adminMocks.listAdminPointsExchanges.mockResolvedValue(pageOf([exchanges[1]]))
    const { app, host } = mount()
    await flush()

    expect(host.querySelector('[data-testid="exchange-fulfill"]')).toBeNull()
    expect(host.textContent).toContain('already been processed')
    app.unmount()

    sessionMock.state.permissions = ['operations:points:read']
    adminMocks.listAdminPointsExchanges.mockResolvedValue(pageOf(exchanges))
    const readOnly = mount()
    await flush()

    expect(readOnly.host.querySelector('[data-testid="exchange-fulfill"]')).toBeNull()
    expect(readOnly.host.textContent).toContain('read-only')
    readOnly.app.unmount()
  })

  it('surfaces load failures', async () => {
    adminMocks.listAdminPointsExchanges.mockRejectedValue(new Error('boom'))
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('boom')
    app.unmount()
  })
})
