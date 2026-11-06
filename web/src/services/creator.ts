import { apiGet, apiPost } from '@/lib/http'
import type { PageResult } from '@/types/browse'
import type { CreatorClaimResult, CreatorTask, CreatorEvidence, CreatorSubmission } from '@/types/creator'

export function fetchCreatorTasks(page = 1, pageSize = 20) {
  return apiGet<PageResult<CreatorTask>>('/api/c/v1/creator/tasks', { page, pageSize })
}

export function claimCreatorTask(id: number) {
  return apiPost<CreatorClaimResult>(`/api/c/v1/creator/tasks/${id}/claim`)
}

export function submitCreatorTask(id: number, body: CreatorSubmission) {
  return apiPost<CreatorClaimResult>(`/api/c/v1/creator/tasks/${id}/submit`, body)
}

export function fetchCreatorEvidence(type: 'review' | 'post', page = 1) {
  return apiGet<PageResult<CreatorEvidence>>('/api/c/v1/creator/evidence', { type, page, pageSize: 20 })
}
