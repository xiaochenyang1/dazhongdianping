import type { UserExpertCertificationBadge } from './auth'

export interface ReviewImage {
  id: number
  url: string
}

export interface ReviewDetail {
  id: number
  shopId: number
  shopName: string
  userId: number
  userName: string
  content: string
  scoreOverall: number
  scoreTaste: number
  scoreEnv: number
  scoreService: number
  cost: number
  currency: string
  likeCount: number
  commentCount: number
  likedByCurrentUser: boolean
  auditStatus: number
  auditStatusText: string
  auditRemark: string
  status: number
  statusText: string
  authorCertification?: UserExpertCertificationBadge | null
  tags: string[]
  images: ReviewImage[]
  createdAt: string
  updatedAt: string
}

export interface ReviewComment {
  id: number
  reviewId: number
  userId: number
  userName: string
  content: string
  parentId: number
  replyTo?: ReviewCommentReply | null
  replies: ReviewComment[]
  mine: boolean
  createdAt: string
}

export interface ReviewCommentReply {
  id: number
  userId: number
  userName: string
  content: string
}

export interface ReviewLikeResult {
  reviewId: number
  liked: boolean
  likeCount: number
}

export interface ReviewReportResult {
  id: number
  reviewId: number
  reason: string
  status: number
  statusText: string
  createdAt: string
}

export interface UserReviewSummary {
  id: number
  shopId: number
  shopName: string
  content: string
  scoreOverall: number
  auditStatus: number
  auditStatusText: string
  auditRemark: string
  status: number
  statusText: string
  tags: string[]
  createdAt: string
  updatedAt: string
}

export interface ReviewSavePayload {
  shopId: number
  content: string
  scoreOverall: number
  scoreTaste: number
  scoreEnv: number
  scoreService: number
  cost: number
  currency: string
  tags: string[]
  images: string[]
}

export interface UserReviewQuery {
  auditStatus?: number
  page?: number
  pageSize?: number
}

export interface ReviewCommentPayload {
  content: string
  replyTo?: number
}

export interface ReviewCommentQuery {
  page?: number
  pageSize?: number
}

export interface ReviewReportPayload {
  reason: string
}
