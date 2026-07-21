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

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((nextResolve) => {
    resolve = nextResolve
  })
  return { promise, resolve }
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

  it('reloads reviews with server-side sort score and image filters', async () => {
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
    browseMocks.fetchShopReviews.mockResolvedValue({
      list: [], total: 0, page: 1, pageSize: 20, hasMore: false,
    })

    const host = document.createElement('div')
    const app = createApp(ShopReviewsView, { shopId: 20001 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    const sort = host.querySelector<HTMLSelectElement>('[data-testid="review-sort"]')
    const score = host.querySelector<HTMLSelectElement>('[data-testid="review-min-score"]')
    const images = host.querySelector<HTMLSelectElement>('[data-testid="review-has-images"]')
    if (!sort || !score || !images) throw new Error('缺少点评筛选控件')
    sort.value = 'popular'
    sort.dispatchEvent(new Event('change'))
    score.value = '4'
    score.dispatchEvent(new Event('change'))
    images.value = 'true'
    images.dispatchEvent(new Event('change'))
    await nextTick()
    host.querySelector<HTMLButtonElement>('[data-testid="apply-review-filters"]')?.click()
    await flushView()

    expect(browseMocks.fetchShopReviews).toHaveBeenLastCalledWith(20001, 1, 20, {
      sort: 'popular',
      minScore: 4,
      hasImages: true,
    })
    app.unmount()
  })

  it('keeps the newest review filters when an older request resolves later', async () => {
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
    browseMocks.fetchShopReviews.mockResolvedValue({
      list: [], total: 0, page: 1, pageSize: 20, hasMore: false,
    })
    const host = document.createElement('div')
    const app = createApp(ShopReviewsView, { shopId: 20001 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    const older = deferred<any>()
    const newer = deferred<any>()
    browseMocks.fetchShopReviews.mockReset()
    browseMocks.fetchShopReviews.mockImplementation((
      _shopId: number,
      _page: number,
      _pageSize: number,
      query?: { sort?: string },
    ) => query?.sort === 'popular' ? older.promise : newer.promise)
    const sort = host.querySelector<HTMLSelectElement>('[data-testid="review-sort"]')
    if (!sort) throw new Error('missing review sort')
    sort.value = 'popular'
    sort.dispatchEvent(new Event('change'))
    await nextTick()
    host.querySelector<HTMLButtonElement>('[data-testid="apply-review-filters"]')?.click()
    await nextTick()
    sort.value = 'score'
    sort.dispatchEvent(new Event('change'))
    await nextTick()
    host.querySelector<HTMLButtonElement>('[data-testid="apply-review-filters"]')?.click()
    await nextTick()

    newer.resolve({
      list: [{ id: 22, userName: 'New', score: 5, content: 'Newest review', likedCount: 0, commentCount: 0, createdAt: '2026-07-20' }],
      total: 1, page: 1, pageSize: 20, hasMore: false,
    })
    await flushView()
    older.resolve({
      list: [{ id: 21, userName: 'Old', score: 1, content: 'Stale review', likedCount: 0, commentCount: 0, createdAt: '2026-07-19' }],
      total: 1, page: 1, pageSize: 20, hasMore: false,
    })
    await flushView()

    expect(host.textContent).toContain('Newest review')
    expect(host.textContent).not.toContain('Stale review')
    app.unmount()
  })
})
