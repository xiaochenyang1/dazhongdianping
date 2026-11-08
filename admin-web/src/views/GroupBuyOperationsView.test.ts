import { createApp, nextTick } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  disposeAdminGroupBuyFailedRefund: vi.fn(),
  getAdminGroupBuySummary: vi.fn(),
  listAdminGroupBuyFailedRefunds: vi.fn(),
  listAdminGroupBuyTeams: vi.fn(),
  reconcileAdminGroupBuyTeam: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'CN' as const,
    permissions: ['data:order:read', 'data:order:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

import GroupBuyOperationsView from './GroupBuyOperationsView.vue'

const mountedApps: ReturnType<typeof createApp>[] = []
const team = {
  id: 81,
  campaignId: 9,
  campaignTitle: '双人拼团',
  shopId: 10001,
  shopName: '渝里火锅',
  cityId: 1,
  region: 'CN' as const,
  status: 2,
  statusText: '已成团',
  memberCount: 2,
  paidCount: 2,
  groupSize: 2,
  memberOrders: 2,
  paidOrders: 2,
  pendingRefunds: 0,
  failedRefunds: 0,
  missingCouponOrders: 1,
  unreleasedInventoryOrders: 0,
  problem: true,
  expireAt: '2026-11-07T18:00:00',
  createdAt: '2026-11-07T15:00:00',
  updatedAt: '2026-11-07T16:00:00',
}

const failedRefund = {
  refundId: 9501,
  orderId: 9301,
  orderNo: 'OD-GROUP-9301',
  teamId: 81,
  campaignTitle: '双人拼团',
  shopName: '渝里火锅',
  amount: 12.8,
  currency: 'CNY',
  channel: 'alipay_mock',
  channelRefundTxn: 'failed_9301',
  channelStatus: 'failed',
  channelFailureReason: 'provider_declined',
  refundStatus: 4,
  auditBy: null,
  auditReason: '',
  auditedAt: null,
  updatedAt: '2026-11-08T15:00:00',
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
  const app = createApp(GroupBuyOperationsView)
  app.mount(host)
  mountedApps.push(app)
  return host
}

describe('GroupBuyOperationsView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    sessionMock.state.region = 'CN'
    sessionMock.state.permissions = ['data:order:read', 'data:order:write']
    adminMocks.getAdminGroupBuySummary.mockResolvedValue({
      windowHours: 24,
      totalTeams: 8,
      activeTeams: 3,
      formedTeams: 4,
      expiredTeams: 1,
      overdueActiveTeams: 0,
      memberOrders: 16,
      paidOrders: 12,
      pendingRefunds: 0,
      failedRefunds: 0,
      missingCouponOrders: 1,
      unreleasedInventoryOrders: 0,
      alerts: [{ severity: 'critical', code: 'voucher_missing', count: 1, message: '存在已成团但未发券订单' }],
    })
    adminMocks.listAdminGroupBuyTeams.mockResolvedValue({ list: [team], total: 1, page: 1, pageSize: 20, hasMore: false })
    adminMocks.listAdminGroupBuyFailedRefunds.mockResolvedValue({
      list: [failedRefund], total: 1, page: 1, pageSize: 20, hasMore: false,
    })
    adminMocks.disposeAdminGroupBuyFailedRefund.mockResolvedValue({
      processed: true,
      alertResolved: false,
      outcome: 'provider_not_refunded',
      refund: { ...failedRefund, auditBy: 1, auditReason: 'provider_not_refunded' },
    })
    adminMocks.reconcileAdminGroupBuyTeam.mockResolvedValue({
      teamId: 81,
      teamStatus: 2,
      expiredOrdersProcessed: 0,
      vouchersIssued: 1,
      failures: 0,
      team: { ...team, missingCouponOrders: 0, problem: false },
    })
  })

  afterEach(() => {
    mountedApps.splice(0).forEach((app) => app.unmount())
    vi.restoreAllMocks()
  })

  it('shows operational alerts and runs targeted recovery', async () => {
    const host = mount()
    await flush()

    expect(adminMocks.listAdminGroupBuyTeams).toHaveBeenCalledWith({
      status: undefined,
      problemOnly: true,
      page: 1,
      pageSize: 20,
    })
    expect(adminMocks.listAdminGroupBuyFailedRefunds).toHaveBeenCalledWith({ page: 1, pageSize: 20 })
    expect(host.textContent).toContain('拼团运维中心')
    expect(host.textContent).toContain('存在已成团但未发券订单')
    expect(host.textContent).toContain('双人拼团')

    const action = [...host.querySelectorAll('button')]
      .find((button) => button.textContent?.trim() === '执行补偿') as HTMLButtonElement
    action.click()
    await flush()

    expect(adminMocks.reconcileAdminGroupBuyTeam).toHaveBeenCalledWith(81)
    expect(host.textContent).toContain('补偿完成：补发券 1')
  })

  it('switches to English and disables recovery for read-only accounts', async () => {
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['data:order:read']
    const host = mount()
    await flush()

    expect(host.textContent).toContain('Group-buy Operations')
    expect(host.textContent).toContain('This account has read-only access.')
    const action = [...host.querySelectorAll('button')]
      .find((button) => button.textContent?.trim() === 'Run recovery') as HTMLButtonElement
    expect(action.disabled).toBe(true)
    expect(host.querySelector<HTMLButtonElement>('[data-testid="refund-refunded-9501"]')!.disabled).toBe(true)
  })

  it('records provider verification without retrying the refund', async () => {
    const host = mount()
    await flush()

    const reference = host.querySelector<HTMLInputElement>('[data-testid="refund-reference-9501"]')!
    const note = host.querySelector<HTMLTextAreaElement>('[data-testid="refund-note-9501"]')!
    reference.value = 'provider_case_9501'
    reference.dispatchEvent(new Event('input'))
    note.value = 'Provider confirmed no money moved'
    note.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="refund-not-refunded-9501"]')!.click()
    await flush()

    expect(adminMocks.disposeAdminGroupBuyFailedRefund).toHaveBeenCalledWith(9501, {
      outcome: 'provider_not_refunded',
      providerReference: 'provider_case_9501',
      note: 'Provider confirmed no money moved',
    })
    expect(host.textContent).toContain('告警继续保留')
  })

  it('requires confirmation before reconciling a provider-confirmed refund', async () => {
    const confirm = vi.spyOn(window, 'confirm').mockReturnValue(true)
    adminMocks.disposeAdminGroupBuyFailedRefund.mockResolvedValue({
      processed: true,
      alertResolved: true,
      outcome: 'provider_refunded',
      refund: { ...failedRefund, refundStatus: 1, channelStatus: 'succeeded' },
    })
    const host = mount()
    await flush()

    const reference = host.querySelector<HTMLInputElement>('[data-testid="refund-reference-9501"]')!
    const note = host.querySelector<HTMLTextAreaElement>('[data-testid="refund-note-9501"]')!
    reference.value = 'provider_refund_9501'
    reference.dispatchEvent(new Event('input'))
    note.value = 'Refund is visible in the provider console'
    note.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="refund-refunded-9501"]')!.click()
    await flush()

    expect(confirm).toHaveBeenCalledOnce()
    expect(adminMocks.disposeAdminGroupBuyFailedRefund).toHaveBeenCalledWith(9501, {
      outcome: 'provider_refunded',
      providerReference: 'provider_refund_9501',
      note: 'Refund is visible in the provider console',
    })
    expect(host.textContent).toContain('相关告警已解除')
    expect(reference.value).toBe('')
    expect(note.value).toBe('')
  })
})
