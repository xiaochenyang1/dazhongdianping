import type { UserExpertCertificationBadge } from './auth'
import type { PageResult } from './browse'

export interface CommunityPost {
  id: number; userId: number; userName: string; title: string; content: string; contentType: number
  shopId?: number | null; dealId?: number | null; likeCount: number; commentCount: number
  authorCertification?: UserExpertCertificationBadge | null
  images: string[]; topics: string[]; createdAt: string
}
export interface CommunityCommentReply {
  id: number
  userId: number
  userName: string
  content: string
}
export interface CommunityComment {
  id:number
  postId:number
  userId:number
  userName:string
  content:string
  parentId:number
  replyTo?: CommunityCommentReply | null
  replies: CommunityComment[]
  mine?: boolean
  createdAt:string
}
export type CommunityPostPage = PageResult<CommunityPost>
export type CommunityCommentPage = PageResult<CommunityComment>
