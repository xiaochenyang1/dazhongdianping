export interface SeckillEvent {
  id: number
  shopId: number
  dealId: number
  title: string
  seckillPrice: number
  currency: string
  stock: number
  sold: number
  startAt?: string
  endAt?: string
}

export interface GroupBuyCampaign {
  id: number
  shopId: number
  dealId: number
  title: string
  groupPrice: number
  currency: string
  groupSize: number
  startAt?: string
  endAt?: string
}

export interface GroupBuyTeam {
  id: number
  campaignId: number
  leaderUserId: number
  status: number
  memberCount: number
  expireAt?: string
}
