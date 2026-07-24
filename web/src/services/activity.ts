import { apiGet } from '@/lib/http'
import type { ActivityDetail, ActivitySummary } from '@/types/activity'

export interface ActivityQuery {
  cityId?: number
  channel?: number
  limit?: number
}

export function fetchActivities(query: ActivityQuery = {}) {
  return apiGet<ActivitySummary[]>('/api/c/v1/activities', query)
}

export function fetchActivityDetail(activityId: number) {
  return apiGet<ActivityDetail>(`/api/c/v1/activities/${activityId}`)
}
