import { apiGet } from '@/lib/http'
import type { RankDetail, RankSummary } from '@/types/rank'

export interface RankQuery {
  cityId?: number
  categoryId?: number
  type?: number
}

export function fetchRanks(query: RankQuery = {}) {
  return apiGet<RankSummary[]>('/api/c/v1/ranks', query)
}

export function fetchRankDetail(rankId: number) {
  return apiGet<RankDetail>(`/api/c/v1/ranks/${rankId}`)
}
