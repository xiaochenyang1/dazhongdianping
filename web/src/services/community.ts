import { apiGet } from '@/lib/http'
import type { CommunityCommentPage, CommunityPost, CommunityPostPage } from '@/types/community'

export function fetchPosts(page = 1, pageSize = 12) { return apiGet<CommunityPostPage>('/api/c/v1/posts', { page, pageSize }) }
export function fetchPost(id: number) { return apiGet<CommunityPost>(`/api/c/v1/posts/${id}`) }
export function fetchPostComments(id: number, page = 1, pageSize = 50) { return apiGet<CommunityCommentPage>(`/api/c/v1/posts/${id}/comments`, { page, pageSize }) }
