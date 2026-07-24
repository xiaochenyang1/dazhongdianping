import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchDeals: vi.fn(),
  fetchDeal: vi.fn(),
  fetchShops: vi.fn(),
  createDeal: vi.fn(),
  updateDeal: vi.fn(),
  updateDealStatus: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)
vi.mock('@/composables/useMerchantSession', () => ({
  useMerchantSession: () => ({ state: { region: 'EU', token: 'token', account: 'owner@example.com' } }),
}))

import DealsView from './DealsView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount(permissions = ['deal:edit']) {
  const host = document.createElement('div')
  const app = createApp(DealsView, { permissions })
  app.mount(host)
  return { app, host }
}

function setInput(host: HTMLElement, name: string, value: string) {
  const el = host.querySelector<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>(`[name="${name}"]`)
  if (!el) throw new Error(`missing field ${name}`)
  el.value = value
  el.dispatchEvent(new Event('input', { bubbles: true }))
  el.dispatchEvent(new Event('change', { bubbles: true }))
}

describe('DealsView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchDeals.mockResolvedValue({
      list: [
        {
          id: 501,
          shopId: 20001,
          shopName: '巴黎川味馆',
          type: 1,
          title: '双人套餐',
          coverImage: 'https://files.example/deal.jpg',
          price: 49.9,
          originalPrice: 68,
          currency: 'EUR',
          stock: 20,
          soldCount: 0,
          auditStatus: 0,
          auditStatusText: '待审核',
          status: 0,
          statusText: '已下架',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
    mocks.fetchShops.mockResolvedValue({
      list: [{ id: 20001, name: '巴黎川味馆' }],
      total: 1,
      page: 1,
      pageSize: 100,
      hasMore: false,
    })
    mocks.fetchDeal.mockResolvedValue({
      id: 501,
      shopId: 20001,
      shopName: '巴黎川味馆',
      type: 1,
      title: '双人套餐',
      coverImage: 'https://files.example/deal.jpg',
      price: 49.9,
      originalPrice: 68,
      currency: 'EUR',
      stock: 20,
      validStart: '2026-07-01',
      validEnd: '2026-12-31',
      rules: '周末通用',
      auditStatus: 0,
      status: 0,
      items: [{ name: '主菜', quantity: 1, price: 30, sort: 1 }],
    })
    mocks.createDeal.mockResolvedValue({ id: 502 })
    mocks.updateDeal.mockResolvedValue({ id: 501 })
    mocks.updateDealStatus.mockResolvedValue({ id: 501, status: 1 })
  })

  it('creates a deal with items and submits for audit', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="deal-create-open"]')?.click()
    await nextTick()

    setInput(host, 'deal-shop-id', '20001')
    setInput(host, 'deal-title', '午市双人餐')
    setInput(host, 'deal-price', '39.9')
    setInput(host, 'deal-original-price', '59.9')
    setInput(host, 'deal-item-name-0', '汤面')
    setInput(host, 'deal-item-quantity-0', '2')
    setInput(host, 'deal-item-price-0', '20')
    setInput(host, 'deal-item-sort-0', '1')
    await nextTick()

    host.querySelector('form')?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.createDeal).toHaveBeenCalledWith({
      shopId: 20001,
      type: 1,
      title: '午市双人餐',
      coverImage: 'https://placehold.co/1200x720/f97316/ffffff?text=Deal',
      price: 39.9,
      originalPrice: 59.9,
      currency: 'EUR',
      stock: 20,
      validStart: null,
      validEnd: null,
      rules: '',
      items: [{ name: '汤面', quantity: 2, price: 20, sort: 1 }],
    })
    expect(host.textContent).toContain('团购已创建并提交审核')
    app.unmount()
  })

  it('loads deal detail for editing and resubmits', async () => {
    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="deal-edit-501"]')?.click()
    await flush()

    expect(mocks.fetchDeal).toHaveBeenCalledWith(501)
    setInput(host, 'deal-title', '改版双人套餐')
    await nextTick()
    host.querySelector('form')?.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await flush()

    expect(mocks.updateDeal).toHaveBeenCalledWith(
      501,
      expect.objectContaining({
        title: '改版双人套餐',
        shopId: 20001,
        items: [{ name: '主菜', quantity: 1, price: 30, sort: 1 }],
      }),
    )
    expect(host.textContent).toContain('团购已更新并重新提交审核')
    app.unmount()
  })
})
