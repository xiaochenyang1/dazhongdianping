import { apiDelete, apiGet, apiPost, apiPut } from '@/lib/http'
import type { PageResult } from '@/types/browse'
import type {
  ReviewComment,
  ReviewCommentPayload,
  ReviewDetail,
  ReviewLikeResult,
  ReviewReportPayload,
  ReviewReportResult,
  ReviewSavePayload,
  UserReviewQuery,
  UserReviewSummary,
} from '@/types/review'

export function createReview(payload: ReviewSavePayload) {
  return apiPost<ReviewDetail>('/api/c/v1/reviews', payload)
}

export function fetchReviewDetail(reviewId: number) {
  return apiGet<ReviewDetail>(`/api/c/v1/reviews/${reviewId}`)
}

export function fetchOwnedReviewDetail(reviewId: number) {
  return apiGet<ReviewDetail>(`/api/c/v1/user/reviews/${reviewId}`)
}

export function updateReview(reviewId: number, payload: ReviewSavePayload) {
  return apiPut<ReviewDetail>(`/api/c/v1/reviews/${reviewId}`, payload)
}

export function toggleReviewLike(reviewId: number) {
  return apiPost<ReviewLikeResult>(`/api/c/v1/reviews/${reviewId}/like`)
}

export function createReviewComment(reviewId: number, payload: ReviewCommentPayload) {
  return apiPost<ReviewComment>(`/api/c/v1/reviews/${reviewId}/comments`, payload)
}

export function listReviewComments(reviewId: number, query?: { page?: number; pageSize?: number }) {
  return apiGet<PageResult<ReviewComment>>(`/api/c/v1/reviews/${reviewId}/comments`, query)
}

export function reportReview(reviewId: number, payload: ReviewReportPayload) {
  return apiPost<ReviewReportResult>(`/api/c/v1/reviews/${reviewId}/report`, payload)
}

export function deleteReview(reviewId: number) {
  return apiDelete<void>(`/api/c/v1/reviews/${reviewId}`)
}

export function listUserReviews(query: UserReviewQuery) {
  return apiGet<PageResult<UserReviewSummary>>('/api/c/v1/user/reviews', query)
}
