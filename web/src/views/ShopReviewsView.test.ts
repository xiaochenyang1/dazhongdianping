import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const browseMocks = vi.hoisted(() => ({
  fetchShopDetail: vi.fn(),
  fetchShopReviews: vi.fn(),
}))

vi.mock('@/services/browse', () => browseMocks)
vi.mock('@/composables/useAppContext', () => ({
  useAppContext: () => ({ state: { region: 'EU' } }),
}))

import ShopReviewsView from './ShopReviewsView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('ShopReviewsView', () => {
  beforeEach(() => {
    browseMocks.fetchShopDetail.mockReset()
    browseMocks.fetchShopReviews.mockReset()
  })

  it('loads later review pages and keeps the server total', async () => {
    browseMocks.fetchShopDetail.mockResolvedValue({
      id: 20001,
      name: 'Maison Sichuan Paris',
      score: 4.6,
      pricePerCapita: 36,
      currency: 'EUR',
      cityName: 'Paris',
      areaName: 'Le Marais',
      categoryName: 'Chinese',
      summary: '川味馆子',
    })
    browseMocks.fetchShopReviews
      .mockResolvedValueOnce({
        list: [
          {
            id: 2,
            userName: 'Newest',
            score: 4.8,
            content: 'Newest review',
            likedCount: 0,
            commentCount: 0,
            createdAt: '2026-07-05 12:00',
          },
        ],
        total: 2,
        page: 1,
        pageSize: 20,
        hasMore: true,
      })
      .mockResolvedValueOnce({
        list: [
          {
            id: 1,
            userName: 'Older',
            score: 4.2,
            content: 'Older review',
            likedCount: 0,
            commentCount: 0,
            createdAt: '2026-07-04 12:00',
          },
        ],
        total: 2,
        page: 2,
        pageSize: 20,
        hasMore: false,
      })

    const host = document.createElement('div')
    const app = createApp(ShopReviewsView, { shopId: 20001 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(browseMocks.fetchShopReviews).toHaveBeenNthCalledWith(1, 20001, 1, 20)
    expect(host.textContent).toContain('公开点评2')

    const loadMoreButton = Array.from(host.querySelectorAll('button')).find((button) =>
      button.textContent?.includes('加载更多点评'),
    )
    expect(loadMoreButton).toBeDefined()
    loadMoreButton?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(browseMocks.fetchShopReviews).toHaveBeenNthCalledWith(2, 20001, 2, 20)
    expect(host.textContent).toContain('Newest review')
    expect(host.textContent).toContain('Older review')
    app.unmount()
  })
})
