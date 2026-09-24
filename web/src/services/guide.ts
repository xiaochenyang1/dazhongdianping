import { apiGet } from '@/lib/http'
import type { GuideArticle, GuidePage } from '@/types/guide'

export function fetchGuides(page = 1, pageSize = 12) {
  return apiGet<GuidePage>('/api/c/v1/guides', { page, pageSize })
}

export function fetchGuide(id: number) {
  return apiGet<GuideArticle>(`/api/c/v1/guides/${id}`)
}
