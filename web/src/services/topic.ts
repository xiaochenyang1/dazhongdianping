import { apiGet } from '@/lib/http'
import type { CommunityPostPage } from '@/types/community'

export interface PublicTopic {
  id: number
  region: 'CN' | 'EU'
  name: string
  postCount: number
  followerCount: number
  recommended: boolean
  pinnedSort: number
  followedByCurrentUser: boolean
  hotScore: number
  postCount7d: number
  likeCount7d: number
  commentCount7d: number
  calculatedAt: string
}

export interface TopicPage {
  list: PublicTopic[]
  total: number
  page: number
  pageSize: number
  hasMore: boolean
}

export function fetchTopics(sort: 'recommended' | 'hot' | 'latest') {
  return apiGet<TopicPage>('/api/c/v1/topics', { sort, page: 1, pageSize: 30 })
}

export function fetchHotTopics() {
  return apiGet<TopicPage>('/api/c/v1/topics/hot', { page: 1, pageSize: 30 })
}

export function fetchTopic(id: number) {
  return apiGet<PublicTopic>(`/api/c/v1/topics/${id}`)
}

export function fetchTopicPosts(id: number) {
  return apiGet<CommunityPostPage>(`/api/c/v1/topics/${id}/posts`, { page: 1, pageSize: 30 })
}
