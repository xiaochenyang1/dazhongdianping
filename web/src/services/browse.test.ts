import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiDelete, apiGet } from '@/lib/http'
import { clearSearchHistory, fetchSearchHistory, fetchSimilarShops, fetchShopReviews, fetchShops } from './browse'

vi.mock('@/lib/http', () => ({
  apiDelete: vi.fn(),
  apiGet: vi.fn(),
}))

describe('fetchShopReviews', () => {
  beforeEach(() => {
    vi.mocked(apiGet).mockReset()
    vi.mocked(apiDelete).mockReset()
  })

  it('sends page and pageSize to the public shop review endpoint', () => {
    fetchShopReviews(10001, 2, 50)

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/shops/10001/reviews', {
      page: 2,
      pageSize: 50,
    })
  })

  it('sends review sorting and image filters to the public endpoint', () => {
    fetchShopReviews(10001, 2, 20, {
      sort: 'popular',
      minScore: 4,
      hasImages: true,
    })

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/shops/10001/reviews', {
      page: 2,
      pageSize: 20,
      sort: 'popular',
      minScore: 4,
      hasImages: true,
    })
  })

  it('uses the unified shop search endpoint for list queries', () => {
    fetchShops({
      keyword: '火锅',
      cityId: 1,
      sort: 'distance',
      lat: 31.2304,
      lng: 121.4737,
    })

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/search/shops', {
      keyword: '火锅',
      cityId: 1,
      sort: 'distance',
      lat: 31.2304,
      lng: 121.4737,
    })
  })

  it('requests nearby similar shops with an explicit limit', () => {
    fetchSimilarShops(10001, 6)

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/shops/10001/similar', {
      limit: 6,
    })
  })

  it('requests the current user search history list', () => {
    fetchSearchHistory(3, 12)

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/search/history', {
      page: 3,
      pageSize: 12,
    })
  })

  it('clears the current user search history', () => {
    clearSearchHistory()

    expect(apiDelete).toHaveBeenCalledWith('/api/c/v1/search/history')
  })
})
