import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiGet, apiPost } from '@/lib/http'
import { cancelWaitlist, fetchMyWaitlist, joinWaitlist } from './waitlist'

vi.mock('@/lib/http', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

describe('waitlist service', () => {
  beforeEach(() => {
    vi.mocked(apiGet).mockReset()
    vi.mocked(apiPost).mockReset()
  })

  it('joins a shop queue', () => {
    joinWaitlist(10001, { tableType: 2, partySize: 4 })
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/shops/10001/waitlist', { tableType: 2, partySize: 4 })
  })

  it('lists my active queue', () => {
    fetchMyWaitlist()
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/waitlist/mine')
  })

  it('cancels a queue entry', () => {
    cancelWaitlist(3)
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/waitlist/3/cancel')
  })
})
