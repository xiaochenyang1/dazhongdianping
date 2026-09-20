import { apiGet, apiPost } from '@/lib/http'
import type { ShopListItem } from '@/types/browse'

/** 用户行为埋点类型：1=浏览店铺 2=收藏 3=下单 4=搜索关键词 */
export type BehaviorEventType = 1 | 2 | 3 | 4

export interface BehaviorEventPayload {
  eventType: BehaviorEventType
  shopId?: number
  categoryId?: number
  keyword?: string
}

export interface RecommendationFeedQuery {
  latitude?: number
  longitude?: number
  cityId?: number
  limit?: number
}

/** 拉取"猜你喜欢"店铺 feed（匿名可用，登录后个性化）。 */
export function fetchRecommendationFeed(query: RecommendationFeedQuery = {}) {
  return apiGet<ShopListItem[]>('/api/c/v1/recommendations/feed', query)
}

/** 上报一条用户行为埋点（需登录；未登录时后端忽略）。 */
export function trackBehavior(payload: BehaviorEventPayload) {
  return apiPost<void>('/api/c/v1/recommendations/behaviors', payload)
}
