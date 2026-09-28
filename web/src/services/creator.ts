import { apiGet, apiPost } from '@/lib/http'
import type { PageResult } from '@/types/browse'
import type { CreatorClaimResult, CreatorTask } from '@/types/creator'

export function fetchCreatorTasks(page = 1, pageSize = 20) {
  return apiGet<PageResult<CreatorTask>>('/api/c/v1/creator/tasks', { page, pageSize })
}

export function claimCreatorTask(id: number) {
  return apiPost<CreatorClaimResult>(`/api/c/v1/creator/tasks/${id}/claim`)
}

export function completeCreatorTask(id: number) {
  return apiPost<CreatorClaimResult>(`/api/c/v1/creator/tasks/${id}/complete`)
}
