import { apiDelete, apiGet } from '@/lib/http'
import type {
  Area,
  Banner,
  CategoryNode,
  City,
  HomeFeedItem,
  PageResult,
  ReviewPreview,
  SearchHistoryItem,
  SearchHotWord,
  SearchSuggestion,
  ShopDetail,
  ShopListItem,
} from '@/types/browse'

export interface ShopQueryParams {
  categoryId?: number
  cityId?: number
  areaId?: number
  keyword?: string
  sort?: string
  lat?: number
  lng?: number
  minPrice?: number
  maxPrice?: number
  minScore?: number
  hasDeal?: boolean
  openNow?: boolean
  page?: number
  pageSize?: number
}

export function fetchCategories() {
  return apiGet<CategoryNode[]>('/api/c/v1/categories')
}

export function fetchCities() {
  return apiGet<City[]>('/api/c/v1/cities')
}

export function fetchAreas(cityId: number) {
  return apiGet<Area[]>(`/api/c/v1/cities/${cityId}/areas`)
}

export function fetchHomeBanners(cityId?: number) {
  return apiGet<Banner[]>('/api/c/v1/home/banners', { cityId })
}

export function fetchHomeFeed(cityId?: number, limit = 6) {
  return apiGet<HomeFeedItem[]>('/api/c/v1/home/feed', { cityId, limit })
}

export function fetchShops(params: ShopQueryParams) {
  return apiGet<PageResult<ShopListItem>>('/api/c/v1/search/shops', params)
}

export function fetchShopDetail(shopId: number) {
  return apiGet<ShopDetail>(`/api/c/v1/shops/${shopId}`)
}

export function fetchSimilarShops(shopId: number, limit = 6) {
  return apiGet<ShopListItem[]>(`/api/c/v1/shops/${shopId}/similar`, { limit })
}

export interface ShopReviewQuery {
  sort?: 'latest' | 'popular' | 'score'
  minScore?: number
  hasImages?: boolean
}

export function fetchShopReviews(shopId: number, page = 1, pageSize = 10, query: ShopReviewQuery = {}) {
  return apiGet<PageResult<ReviewPreview>>(`/api/c/v1/shops/${shopId}/reviews`, {
    page,
    pageSize,
    ...query,
  })
}

export function fetchSearchSuggestions(keyword: string, limit = 6) {
  return apiGet<SearchSuggestion[]>('/api/c/v1/search/suggest', { kw: keyword, limit })
}

export function fetchHotSearchWords(limit = 6) {
  return apiGet<SearchHotWord[]>('/api/c/v1/search/hot', { limit })
}

export function fetchSearchHistory(page = 1, pageSize = 10) {
  return apiGet<PageResult<SearchHistoryItem>>('/api/c/v1/search/history', { page, pageSize })
}

export function clearSearchHistory() {
  return apiDelete<void>('/api/c/v1/search/history')
}
