import type { PageResult } from './browse'

export interface FavoriteTarget {
  id: number
  merchantId?: number | null
  name: string
  coverUrl: string
  score: number
  pricePerCapita: number
  currency: string
  address: string
  cityName: string
  areaName: string
  hasDeal: boolean
  openNow: boolean
  tags: string[]
  merchantCertification?: { code: string; label: string } | null
}

export interface FavoriteItem {
  id: number
  targetType: number
  targetTypeText: string
  targetId: number
  target: FavoriteTarget
  createdAt: string
}

export type FavoritePage = PageResult<FavoriteItem>
