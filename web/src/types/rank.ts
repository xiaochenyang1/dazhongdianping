export interface RankSummary {
  id: number
  name: string
  type: number
  typeText: string
  region: 'CN' | 'EU'
  cityId: number
  cityName: string
  categoryId: number
  categoryName: string
  period: string
  itemCount: number
  coverUrl: string
  topShopName: string
  updatedAt: string
}

export interface RankShop {
  id: number
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
}

export interface RankItem {
  position: number
  rankScore: number
  reason: string
  shop: RankShop
}

export interface RankDetail extends Omit<RankSummary, 'itemCount' | 'coverUrl' | 'topShopName'> {
  items: RankItem[]
}
