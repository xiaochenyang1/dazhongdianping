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

export interface RankItem {
  position: number
  rankScore: number
  reason: string
  shop: RankShop
}

export interface RankDetail extends Omit<RankSummary, 'itemCount' | 'coverUrl' | 'topShopName'> {
  items: RankItem[]
}
