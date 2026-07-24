import type { PageResult } from './browse'

export interface ShopBrowseHistoryItem {
  id: number
  shopId: number
  shopName: string
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
  viewCount: number
  lastViewedAt: string
}

export type ShopBrowseHistoryPage = PageResult<ShopBrowseHistoryItem>
