import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const browseMocks = vi.hoisted(() => ({
  fetchShopDetail: vi.fn(),
  fetchSimilarShops: vi.fn().mockResolvedValue([]),
  fetchShopReviews: vi.fn(),
}))
const routeMocks = vi.hoisted(() => ({
  route: undefined as unknown as { params: { id: string }; fullPath: string },
}))

vi.mock('@/services/browse', () => browseMocks)
vi.mock('@/services/trade', () => ({ fetchShopDeals: vi.fn().mockResolvedValue([]) }))
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: { region: 'EU' } }),
}))
vi.mock('vue-router', async (importOriginal) => {
  const actual = await importOriginal<typeof import('vue-router')>()
  const { reactive } = await import('vue')
  routeMocks.route = reactive({ params: { id: '20001' }, fullPath: '/shops/20001' })
  return {
    ...actual,
    useRoute: () => routeMocks.route,
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
  beforeEach(() => {
    routeMocks.route.params.id = '20001'
    routeMocks.route.fullPath = '/shops/20001'
  })

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

  it('uses the native share contract when the browser provides it', async () => {
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
      hasDeal: false,
      openNow: true,
      tags: [],
      photos: [],
      recommendedDishes: [],
    })
    browseMocks.fetchShopReviews.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 3, hasMore: false })
    const share = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'share', { configurable: true, value: share })

    const host = document.createElement('div')
    const app = createApp(ShopDetailView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="share-shop"]')?.click()
    await flushView()

    expect(share).toHaveBeenCalledWith(expect.objectContaining({ title: 'Maison Sichuan Paris', url: expect.any(String) }))
    expect(host.textContent).toContain('分享链接已准备好')
    app.unmount()
    Reflect.deleteProperty(navigator, 'share')
  })

  it('renders nearby similar shops with their real distance', async () => {
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
      hasDeal: false,
      openNow: true,
      tags: [],
      photos: [],
      recommendedDishes: [],
    })
    browseMocks.fetchShopReviews.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 3, hasMore: false })
    browseMocks.fetchSimilarShops.mockResolvedValue([{
      id: 20003,
      name: 'Nearby Sichuan Bistro',
      coverUrl: '/nearby.jpg',
      score: 4.5,
      pricePerCapita: 31,
      currency: 'EUR',
      address: 'Paris',
      areaName: 'Le Marais',
      cityName: 'Paris',
      hasDeal: true,
      openNow: true,
      tags: ['Chinese'],
      distanceMeters: 850,
    }])

    const host = document.createElement('div')
    const app = createApp(ShopDetailView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(host.textContent).toContain('附近相似门店')
    expect(host.textContent).toContain('Nearby Sichuan Bistro')
    expect(host.textContent).toContain('850 m')
    app.unmount()
  })

  it('publishes canonical metadata and a Restaurant JSON-LD document', async () => {
    browseMocks.fetchShopDetail.mockResolvedValue({
      id: 20001,
      name: 'Maison Sichuan Paris',
      coverUrl: 'https://cdn.example.test/shop.jpg',
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
      recommendedDishes: [],
    })
    browseMocks.fetchShopReviews.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 3, hasMore: false })

    const host = document.createElement('div')
    const app = createApp(ShopDetailView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    const canonical = document.head.querySelector('link[rel="canonical"]')
    expect(canonical?.getAttribute('href')).toBe(`${window.location.origin}/shops/20001`)
    expect(document.title).toContain('Maison Sichuan Paris')
    expect(document.head.querySelector('meta[name="description"]')?.getAttribute('content')).toContain('川味馆子')
    const schema = JSON.parse(document.head.querySelector('script[type="application/ld+json"]')?.textContent ?? '{}')
    expect(schema).toMatchObject({ '@type': 'Restaurant', name: 'Maison Sichuan Paris', url: canonical?.getAttribute('href') })
    expect(schema.address).toMatchObject({ '@type': 'PostalAddress', addressLocality: 'Paris' })
    app.unmount()
  })

  it('clears a reused route and ignores stale shop detail responses', async () => {
    const pending = new Map<number, (value: any) => void>()
    browseMocks.fetchShopDetail.mockImplementation((id: number) => new Promise((resolve) => pending.set(id, resolve)))
    browseMocks.fetchShopReviews.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 3, hasMore: false })
    browseMocks.fetchSimilarShops.mockResolvedValue([])
    const detail = (id: number, name: string) => ({
      id,
      name,
      coverUrl: '/shop.jpg',
      score: 4.6,
      tasteScore: 4.7,
      envScore: 4.4,
      serviceScore: 4.5,
      pricePerCapita: 36,
      currency: 'EUR',
      address: 'Paris',
      phone: '+33142345678',
      businessHours: '11:30-22:30',
      summary: `${name} summary`,
      categoryName: 'Chinese',
      cityName: 'Paris',
      areaName: 'Le Marais',
      hasDeal: false,
      openNow: true,
      tags: [],
      photos: [],
      recommendedDishes: [],
    })
    const host = document.createElement('div')
    const app = createApp(ShopDetailView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    pending.get(20001)?.(detail(20001, 'Old shop'))
    await flushView()
    expect(host.textContent).toContain('Old shop')

    routeMocks.route.params.id = '20002'
    routeMocks.route.fullPath = '/shops/20002'
    await nextTick()
    expect(document.title).not.toContain('Old shop')
    routeMocks.route.params.id = '20003'
    routeMocks.route.fullPath = '/shops/20003'
    await nextTick()

    pending.get(20003)?.(detail(20003, 'Newest shop'))
    await flushView()
    pending.get(20002)?.(detail(20002, 'Stale shop'))
    await flushView()

    expect(host.textContent).toContain('Newest shop')
    expect(host.textContent).not.toContain('Stale shop')
    expect(document.head.querySelector('link[rel="canonical"]')?.getAttribute('href'))
      .toBe(`${window.location.origin}/shops/20003`)
    app.unmount()
  })
})
