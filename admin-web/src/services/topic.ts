import { apiGet, apiPost, apiPut } from '@/lib/http'
import type { PageResult } from '@/types/admin'

export interface AdminTopic {
  id: number
  region: 'CN' | 'EU'
  name: string
  postCount: number
  followerCount: number
  recommended: boolean
  pinnedSort: number
  status: number
  mergedToId: number | null
  hotScore: number
  postCount7d: number
  likeCount7d: number
  commentCount7d: number
  calculatedAt: string
}

export interface TopicListQuery {
  status?: number
  recommended?: boolean
  keyword: string
  page: number
  pageSize: number
}

export interface TopicRecalculateResult {
  region: 'CN' | 'EU'
  calculatedAt: string
}

export function listTopics(query: TopicListQuery) {
  return apiGet<PageResult<AdminTopic>>('/api/admin/v1/topics', query)
}

export function updateTopic(id: number, payload: { name: string }) {
  return apiPut<AdminTopic>(`/api/admin/v1/topics/${id}`, payload)
}

export function updateTopicRecommendation(
  id: number,
  payload: { recommended: boolean; pinnedSort: number },
) {
  return apiPut<AdminTopic>(`/api/admin/v1/topics/${id}/recommendation`, payload)
}

export function updateTopicStatus(id: number, status: number) {
  return apiPut<AdminTopic>(`/api/admin/v1/topics/${id}/status`, { status })
}

export function mergeTopic(id: number, targetTopicId: number) {
  return apiPost<AdminTopic>(`/api/admin/v1/topics/${id}/merge`, { targetTopicId })
}

export function recalculateTopicHot() {
  return apiPost<TopicRecalculateResult>('/api/admin/v1/topics/recalculate-hot')
}
