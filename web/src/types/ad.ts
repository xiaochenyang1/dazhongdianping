/** 固定广告位召回的一条广告(门店)。 */
export interface AdSlot {
  campaignId: number
  shopId: number
  shopName: string
  coverUrl: string
  score: number
  ad: boolean
}
