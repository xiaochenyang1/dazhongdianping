import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiGet, apiPost } from '@/lib/http'
import { fetchAdSlots, reportAdClick } from './ad'

vi.mock('@/lib/http', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

describe('ad service', () => {
  beforeEach(() => {
    vi.mocked(apiGet).mockReset()
    vi.mocked(apiPost).mockReset()
  })

  it('fetches keyword-targeted search ad slots', () => {
    fetchAdSlots(1, '火锅', 3)
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/ads', { slotType: 1, keyword: '火锅', limit: 3 })
  })

  it('reports an ad click to the billing endpoint', () => {
    reportAdClick(8001)
    expect(apiPost).toHaveBeenCalledWith('/api/c/v1/ads/8001/click')
  })
})
