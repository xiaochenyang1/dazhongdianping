import { createApp, nextTick, reactive, type App } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const merchantMocks = vi.hoisted(() => ({
  fetchShops: vi.fn(),
  fetchDeals: vi.fn(),
}))
const campaignMocks = vi.hoisted(() => ({
  createMerchantCoupon: vi.fn(),
  createMerchantGroupBuy: vi.fn(),
  createMerchantSeckill: vi.fn(),
  fetchMerchantCoupons: vi.fn(),
  fetchMerchantGroupBuy: vi.fn(),
  fetchMerchantSeckill: vi.fn(),
}))

vi.mock('@/services/merchant', () => merchantMocks)
vi.mock('@/services/ops', () => campaignMocks)
const state = reactive({ region: 'EU' })
vi.mock('@/composables/useMerchantSession', () => ({ useMerchantSession: () => ({ state }) }))

import MarketingView from './MarketingView.vue'

const mounted: App[] = []

async function flush() {
  for (let index = 0; index < 8; index += 1) await Promise.resolve()
  await nextTick()
}

function mount(permissions = ['marketing:manage', 'deal:edit']) {
  const host = document.createElement('div')
  const app = createApp(MarketingView, { permissions })
  app.mount(host)
  mounted.push(app)
  return host
}

function input(host: HTMLElement, testId: string, value: string) {
  const element = host.querySelector<HTMLInputElement>(`[data-testid="${testId}"]`)
  if (!element) throw new Error(`missing input: ${testId}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

describe('MarketingView seckill management', () => {
  beforeEach(() => {
    Object.values(merchantMocks).forEach((mock) => mock.mockReset())
    Object.values(campaignMocks).forEach((mock) => mock.mockReset())
    state.region = 'EU'
    merchantMocks.fetchShops.mockResolvedValue({
      list: [{ id: 20001, name: 'Maison Sichuan Paris' }],
      total: 1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
    merchantMocks.fetchDeals.mockResolvedValue({
      list: [{
        id: 41001,
        shopId: 20001,
        type: 1,
        title: 'Dinner for two',
        coverImage: '',
        price: 48,
        originalPrice: 58,
        currency: 'EUR',
        stock: 30,
        auditStatus: 1,
        status: 1,
      }],
      total: 1,
      page: 1,
      pageSize: 100,
      hasMore: false,
    })
    campaignMocks.fetchMerchantCoupons.mockResolvedValue([])
    campaignMocks.fetchMerchantGroupBuy.mockResolvedValue([])
    campaignMocks.fetchMerchantSeckill.mockResolvedValue([{
      id: 61,
      shopId: 20001,
      dealId: 41001,
      title: 'Paris flash sale',
      seckillPrice: 29,
      currency: 'EUR',
      stock: 20,
      sold: 4,
      auditStatus: 2,
      rejectReason: '',
      status: 1,
    }])
  })

  afterEach(() => mounted.splice(0).forEach((app) => app.unmount()))

  it('uses an approved active offer, shows reserved allocation and prevents duplicate creation', async () => {
    let complete!: () => void
    campaignMocks.createMerchantSeckill.mockImplementation(() => new Promise<void>((resolve) => { complete = resolve }))
    const host = mount()
    await flush()

    expect(merchantMocks.fetchDeals).toHaveBeenCalledWith({
      shopId: 20001,
      status: 1,
      auditStatus: 1,
      pageSize: 100,
    })
    expect(host.textContent).toContain('Sold and reserved / allocation 4/20')
    expect(host.querySelector<HTMLSelectElement>('[data-testid="seckill-deal"]')?.value).toBe('41001')

    input(host, 'seckill-title', 'Weekend dinner')
    input(host, 'seckill-price', '25.5')
    input(host, 'seckill-stock', '12')
    input(host, 'seckill-start', '2026-11-08T18:00')
    input(host, 'seckill-end', '2026-11-08T20:00')
    const form = host.querySelector<HTMLFormElement>('[data-testid="seckill-create"]')!
    form.dispatchEvent(new Event('submit', { cancelable: true }))
    form.dispatchEvent(new Event('submit', { cancelable: true }))
    await flush()

    expect(campaignMocks.createMerchantSeckill).toHaveBeenCalledTimes(1)
    expect(campaignMocks.createMerchantSeckill).toHaveBeenCalledWith({
      dealId: 41001,
      title: 'Weekend dinner',
      seckillPrice: 25.5,
      stock: 12,
      startAt: '2026-11-08T18:00:00',
      endAt: '2026-11-08T20:00:00',
      shopId: 20001,
    })
    expect(form.querySelector<HTMLButtonElement>('button[type="submit"]')?.disabled).toBe(true)

    complete()
    await flush()
    expect(campaignMocks.fetchMerchantSeckill).toHaveBeenCalledTimes(2)
  })

  it('keeps creation failures visible and retryable', async () => {
    campaignMocks.createMerchantSeckill.mockRejectedValueOnce(new Error('allocation changed'))
    const host = mount()
    await flush()

    input(host, 'seckill-title', 'Retry sale')
    input(host, 'seckill-price', '21')
    input(host, 'seckill-stock', '5')
    input(host, 'seckill-start', '2026-11-08T18:00')
    input(host, 'seckill-end', '2026-11-08T20:00')
    host.querySelector<HTMLFormElement>('[data-testid="seckill-create"]')!
      .dispatchEvent(new Event('submit', { cancelable: true }))
    await flush()

    expect(host.textContent).toContain('allocation changed')
    expect(host.querySelector<HTMLButtonElement>('[data-testid="seckill-create"] button[type="submit"]')?.disabled).toBe(false)
  })

  it('does not load offer choices or expose creation without the required permissions', async () => {
    const host = mount([])
    await flush()

    expect(merchantMocks.fetchDeals).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="seckill-create"]')).toBeNull()
    expect(campaignMocks.createMerchantSeckill).not.toHaveBeenCalled()
  })
})
