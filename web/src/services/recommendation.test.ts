import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiGet, apiPost } from '@/lib/http'
import { fetchRecommendationFeed, trackBehavior } from './recommendation'

vi.mock('@/lib/http', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

describe('recommendation service', () => {
  beforeEach(() => {
    vi.mocked(apiGet).mockReset()
    vi.mocked(apiPost).mockReset()
  })

  it('requests the personalized feed with location and city filters', () => {
    fetchRecommendationFeed({ latitude: 48.85, longitude: 2.35, cityId: 101, limit: 6 })

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/recommendations/feed', {
      latitude: 48.85,
      longitude: 2.35,
      cityId: 101,
      limit: 6,
    })
  })

  it('requests the feed with defaults when no query is given', () => {
    fetchRecommendationFeed()

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/recommendations/feed', {})
  })

  it('reports a behavior event', () => {
    trackBehavior({ eventType: 3, shopId: 20001 })

    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/recommendations/behaviors', {
      eventType: 3,
      shopId: 20001,
    })
  })
})
