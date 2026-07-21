import type { UserExpertCertificationBadge } from './auth'

export type Region = 'CN' | 'EU'

export interface CategoryNode {
  id: number
  name: string
  children: CategoryNode[]
}

export interface City {
  id: number
  code: string
  name: string
}

export interface Area {
  id: number
  name: string
}

export interface Banner {
  id: number
  title: string
  subtitle: string
  imageUrl: string
  linkUrl: string
}

export interface HomeFeedItem {
  id: number
  type: string
  title: string
  subtitle: string
  coverUrl: string
  shopId: number | null
}

export interface ShopListItem {
  id: number
  name: string
  coverUrl: string
  score: number
  pricePerCapita: number
  currency: string
  address: string
  areaName: string
  cityName: string
  hasDeal: boolean
  openNow: boolean
  tags: string[]
  distanceMeters: number | null
}

export interface SearchSuggestion {
  term: string
  type: 'shop' | 'category'
  refId: number
}

export interface SearchHotWord {
  term: string
  score: number
}

export interface SearchHistoryItem {
  id: number
  keyword: string
  region: Region
  searchType: number
  updatedAt: string
}

export interface Photo {
  id: number
  imageUrl: string
}

export interface Dish {
  id: number
  name: string
  price: number
  recommendReason: string
}

export interface ReviewPreview {
  id: number
  userName: string
  authorCertification?: UserExpertCertificationBadge | null
  score: number
  content: string
  likedCount: number
  commentCount: number
  createdAt: string
}

export interface ShopDetail {
  id: number
  name: string
  coverUrl: string
  score: number
  tasteScore: number
  envScore: number
  serviceScore: number
  pricePerCapita: number
  currency: string
  address: string
  phone: string
  businessHours: string
  summary: string
  categoryName: string
  cityName: string
  areaName: string
  hasDeal: boolean
  openNow: boolean
  tags: string[]
  photos: Photo[]
  recommendedDishes: Dish[]
}

export interface PageResult<T> {
  list: T[]
  total: number
  page: number
  pageSize: number
  hasMore: boolean
}
