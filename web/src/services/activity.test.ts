import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiGet } from '@/lib/http'
import { fetchActivities, fetchActivityDetail } from './activity'

vi.mock('@/lib/http', () => ({
  apiGet: vi.fn(),
}))

describe('activity service', () => {
  beforeEach(() => {
    vi.mocked(apiGet).mockReset()
  })

  it('requests the public activity list with city and channel filters', () => {
    fetchActivities({ cityId: 101, channel: 4, limit: 8 })

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/activities', {
      cityId: 101,
      channel: 4,
      limit: 8,
    })
  })

  it('requests a public activity detail by id', () => {
    fetchActivityDetail(5001)

    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/activities/5001')
  })
})
