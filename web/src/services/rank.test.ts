import { describe, expect, it, vi } from 'vitest'
import { apiGet } from '@/lib/http'
import { fetchRankDetail, fetchRanks } from './rank'

vi.mock('@/lib/http', () => ({ apiGet: vi.fn() }))

describe('rank service', () => {
  it('loads public ranks with scope filters', () => {
    fetchRanks({ cityId: 1, categoryId: 102, type: 1 })
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/ranks', { cityId: 1, categoryId: 102, type: 1 })
  })

  it('loads one public rank snapshot', () => {
    fetchRankDetail(30001)
    expect(apiGet).toHaveBeenCalledWith('/api/c/v1/ranks/30001')
  })
})
