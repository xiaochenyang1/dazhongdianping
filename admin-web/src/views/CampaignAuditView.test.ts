import { createApp, nextTick, reactive, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  auditGroupBuy: vi.fn(),
  auditSeckill: vi.fn(),
  fetchAdminGroupBuys: vi.fn(),
  fetchAdminSeckills: vi.fn(),
}))
vi.mock('@/services/ops', () => mocks)
const state = reactive({ region: 'EU', permissions: ['operations:marketing:write'] })
vi.mock('@/composables/useAdminSession', () => ({ useAdminSession: () => ({ state }) }))

import CampaignAuditView from './CampaignAuditView.vue'

const mounted: App[] = []

async function flush() {
  for (let index = 0; index < 8; index += 1) await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(CampaignAuditView)
  app.mount(host)
  mounted.push(app)
  return host
}

describe('CampaignAuditView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    state.region = 'EU'
    state.permissions = ['operations:marketing:write']
    mocks.fetchAdminSeckills.mockResolvedValue([
      { id: 61, shopId: 20001, title: 'Pending flash sale', auditStatus: 1, status: 1, rejectReason: '', currency: 'EUR', seckillPrice: 25, stock: 10, sold: 3 },
      { id: 62, shopId: 20001, title: 'Approved flash sale', auditStatus: 2, status: 1, rejectReason: '', currency: 'EUR', seckillPrice: 30, stock: 8, sold: 2 },
    ])
    mocks.fetchAdminGroupBuys.mockResolvedValue([
      { id: 71, shopId: 20001, title: 'Pending group buy', auditStatus: 1, status: 1, rejectReason: '', currency: 'EUR', groupPrice: 35, groupSize: 3 },
    ])
    mocks.auditSeckill.mockResolvedValue({})
    mocks.auditGroupBuy.mockResolvedValue({})
  })

  afterEach(() => mounted.splice(0).forEach((app) => app.unmount()))

  it('shows reserved allocation, filters completed campaigns and approves once', async () => {
    let complete!: () => void
    mocks.auditSeckill.mockImplementation(() => new Promise<void>((resolve) => { complete = resolve }))
    const host = mount()
    await flush()

    expect(host.textContent).toContain('已售及待支付/总名额')
    expect(host.querySelector('[data-testid="seckill-row-61"]')?.textContent).toContain('3/10')
    expect(host.querySelector('[data-testid="seckill-row-62"]')).toBeNull()

    const approve = host.querySelector<HTMLButtonElement>('[data-testid="seckill-approve-61"]')!
    approve.click()
    approve.click()
    await flush()
    expect(mocks.auditSeckill).toHaveBeenCalledTimes(1)
    expect(mocks.auditSeckill).toHaveBeenCalledWith(61, true, '')

    complete()
    await flush()
    expect(mocks.fetchAdminSeckills).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('已通过')
  })

  it('requires and submits a trimmed rejection reason', async () => {
    const host = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="groupbuy-reject-71"]')!.click()
    await flush()
    expect(host.textContent).toContain('驳回需填写原因')
    expect(mocks.auditGroupBuy).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLInputElement>('[data-testid="campaign-reject-reason"]')!
    reason.value = '  缺少活动规则  '
    reason.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="groupbuy-reject-71"]')!.click()
    await flush()

    expect(mocks.auditGroupBuy).toHaveBeenCalledWith(71, false, '缺少活动规则')
    expect(reason.value).toBe('')
    expect(host.textContent).toContain('已驳回')
  })

  it('keeps the page read-only without the write permission', async () => {
    state.permissions = []
    const host = mount()
    await flush()

    expect(host.querySelector('[data-testid="campaign-reject-reason"]')).toBeNull()
    expect(host.querySelector('[data-testid="seckill-approve-61"]')).toBeNull()
    expect(host.querySelector('[data-testid="groupbuy-reject-71"]')).toBeNull()
  })
})
