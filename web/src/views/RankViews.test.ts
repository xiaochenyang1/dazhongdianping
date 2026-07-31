import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const rankMocks = vi.hoisted(() => ({
  fetchRanks: vi.fn(),
  fetchRankDetail: vi.fn(),
}))
const contextMocks = vi.hoisted(() => ({ state: { region: 'EU' as const, cityId: 101 } }))

vi.mock('@/services/rank', () => rankMocks)
vi.mock('@/composables/useAppContext', () => ({ useAppContext: () => contextMocks }))
vi.mock('vue-router', () => ({
  RouterLink: defineComponent({ props: ['to'], template: '<a><slot /></a>' }),
}))

import RankListView from './RankListView.vue'
import RankDetailView from './RankDetailView.vue'

const RouterLinkStub = defineComponent({ props: ['to'], template: '<a><slot /></a>' })

async function mount(component: any, props: Record<string, unknown> = {}) {
  const host = document.createElement('div')
  const app = createApp(component, props)
  app.component('RouterLink', RouterLinkStub)
  app.mount(host)
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  return { app, host }
}

describe('Rank views', () => {
  beforeEach(() => {
    rankMocks.fetchRanks.mockReset()
    rankMocks.fetchRankDetail.mockReset()
    contextMocks.state.region = 'EU'
    contextMocks.state.cityId = 101
  })

  it('localizes ranking list and preserves the published place name', async () => {
    rankMocks.fetchRanks.mockResolvedValue([{
      id: 1, name: 'Paris winter list', type: 2, typeText: '好评榜', region: 'EU', cityId: 101,
      cityName: 'Paris', categoryId: 2, categoryName: 'Dining', period: '2026 Q3', itemCount: 2,
      coverUrl: '/rank.jpg', topShopName: 'Maison Sichuan Paris', updatedAt: '2026-07-15 12:00',
    }])
    const { app, host } = await mount(RankListView)
    expect(host.textContent).toContain('City rankings')
    expect(host.textContent).toContain('Top rated')
    expect(host.textContent).toContain('No. 1: Maison Sichuan Paris')
    expect(host.textContent).toContain('15/07/2026 12:00')
    expect(host.textContent).not.toMatch(/[一-龥]/)
    app.unmount()
  })

  it('localizes ranking detail and certification badges', async () => {
    rankMocks.fetchRankDetail.mockResolvedValue({
      id: 1, name: 'Paris winter list', type: 1, typeText: '必吃榜', region: 'EU', cityId: 101,
      cityName: 'Paris', categoryId: 2, categoryName: 'Dining', period: '2026 Q3', updatedAt: '2026-07-15 12:00',
      items: [{ position: 1, rankScore: 9.8, reason: 'Worth a visit', shop: {
        id: 20001, name: 'Maison Sichuan Paris', coverUrl: '/shop.jpg', score: 4.7,
        pricePerCapita: 36, currency: 'EUR', address: 'Paris', cityName: 'Paris', areaName: 'Le Marais',
        hasDeal: true, openNow: true, tags: ['Chinese'], merchantCertification: { code: 'verified_merchant', label: '认证商户' },
      }}],
    })
    const { app, host } = await mount(RankDetailView, { rankId: 1 })
    expect(host.textContent).toContain('Must-try')
    expect(host.textContent).toContain('Average €36 EUR')
    expect(host.textContent).toContain('Verified merchant')
    expect(host.textContent).not.toContain('认证商户')
    app.unmount()
  })
})
