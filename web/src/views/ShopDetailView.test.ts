import { createApp, defineComponent, nextTick } from 'vue'
import { describe, expect, it, vi } from 'vitest'

const browseMocks = vi.hoisted(() => ({
  fetchShopDetail: vi.fn(),
  fetchShopReviews: vi.fn(),
}))

vi.mock('@/services/browse', () => browseMocks)
vi.mock('@/services/trade', () => ({ fetchShopDeals: vi.fn().mockResolvedValue([]) }))
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: { region: 'EU' } }),
}))
vi.mock('vue-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('vue-router')>()
  return {
    ...actual,
    useRoute: () => ({ params: { id: '20001' } }),
  }
})

import ShopDetailView from './ShopDetailView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('ShopDetailView', () => {
  it('renders the response currency and phone without a hard-coded yuan symbol', async () => {
    browseMocks.fetchShopDetail.mockResolvedValue({
      id: 20001,
      name: 'Maison Sichuan Paris',
      coverUrl: '/shop.jpg',
      score: 4.6,
      tasteScore: 4.7,
      envScore: 4.4,
      serviceScore: 4.5,
      pricePerCapita: 36,
      currency: 'EUR',
      address: '12 Rue du Temple, Paris',
      phone: '+33142345678',
      businessHours: '11:30-22:30',
      summary: '川味馆子',
      categoryName: 'Chinese',
      cityName: 'Paris',
      areaName: 'Le Marais',
      hasDeal: true,
      openNow: true,
      tags: ['Spicy'],
      photos: [],
      recommendedDishes: [
        { id: 1, name: 'Mapo tofu', price: 14, recommendReason: 'Spicy' },
      ],
    })
    browseMocks.fetchShopReviews.mockResolvedValue({
      list: [],
      total: 0,
      page: 1,
      pageSize: 3,
      hasMore: false,
    })

    const host = document.createElement('div')
    const app = createApp(ShopDetailView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(host.textContent).toContain('€36 EUR')
    expect(host.textContent).toContain('€14 EUR')
    expect(host.textContent).toContain('+33142345678')
    expect(host.textContent).not.toContain('¥')
    app.unmount()
  })
})
