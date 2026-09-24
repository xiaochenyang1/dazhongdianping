import { apiGet, apiPost } from '@/lib/http'

export interface ReviewHelpful {
  reviewId: number
  voted: boolean
  helpfulCount: number
}

export interface ReviewTranslation {
  id: number
  reviewId: number
  userId: number
  targetLang: string
  content: string
  createdAt?: string
  updatedAt?: string
}

export interface DishReview {
  id: number
  shopId: number
  dishId: number
  userId: number
  score: number
  content: string
  createdAt?: string
}

export interface ShopAmenities {
  chineseService: boolean
  chineseMenu: boolean
  acceptAlipay: boolean
  acceptWechat: boolean
}

export interface LevelPrivileges {
  level: number
  levelName: string
  growthValue: number
  privileges: Record<string, unknown>
}

export function toggleReviewHelpful(reviewId: number) {
  return apiPost<ReviewHelpful>(`/api/c/v1/reviews/${reviewId}/helpful`)
}

export function fetchReviewTranslations(reviewId: number, lang?: string) {
  return apiGet<ReviewTranslation[]>(`/api/c/v1/reviews/${reviewId}/translations`, { lang })
}

export function saveReviewTranslation(reviewId: number, payload: { targetLang: string; content: string }) {
  return apiPost<ReviewTranslation>(`/api/c/v1/reviews/${reviewId}/translations`, payload)
}

export function fetchDishReviews(shopId: number, dishId: number) {
  return apiGet<DishReview[]>(`/api/c/v1/shops/${shopId}/dishes/${dishId}/reviews`)
}

export function createDishReview(shopId: number, dishId: number, payload: { score: number; content: string }) {
  return apiPost<DishReview>(`/api/c/v1/shops/${shopId}/dishes/${dishId}/reviews`, payload)
}

export function fetchShopAmenities(shopId: number) {
  return apiGet<ShopAmenities>(`/api/c/v1/shops/${shopId}/amenities`)
}

export function fetchLevelPrivileges() {
  return apiGet<LevelPrivileges>('/api/c/v1/user/level-privileges')
}
