import { apiGet, apiPost } from '@/lib/http'
import type { PageResult } from '@/types/admin'

export interface CreatorClaim {
  id: number
  taskId: number
  userId: number
  taskTitle: string
  taskDescription: string
  rewardPoints: number
  claimStatus: number
  evidenceType: 'review' | 'post' | null
  evidenceId: number | null
  submissionNote: string
  submissionVersion: number
  submittedAt: string | null
  reviewNote: string
  reviewedAt: string | null
  completedAt: string | null
  evidenceHash: string | null
  evidence: {
    id: number
    title: string
    content: string
    shopId: number | null
    score: number | null
    images: string[]
    createdAt: string
    updatedAt: string
  } | null
}

export function fetchCreatorClaims(page = 1, status?: number) {
  return apiGet<PageResult<CreatorClaim>>('/api/admin/v1/creator/claims', { page, pageSize: 20, status })
}

export function reviewCreatorClaim(id: number, body: {
  approved: boolean
  submissionVersion: number
  evidenceHash: string | null
  note: string
}) {
  return apiPost<CreatorClaim>(`/api/admin/v1/creator/claims/${id}/review`, body)
}
