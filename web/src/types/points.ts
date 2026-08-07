/** C-end 积分商城商品（与 backend PointsProductResponse 对齐）。 */
export interface PointsProduct {
  id: number
  region: string
  name: string
  coverImage: string
  description: string
  pointsPrice: number
  stock: number
  /** <=0 表示不限每人兑换次数。 */
  exchangeLimitPerUser: number
  exchangeCount: number
  /** 1=自动发放 2=人工发放 */
  fulfillType: number
  fulfillTypeText: string
  status: number
  sort: number
  soldOut: boolean
  createdAt: string
  updatedAt: string
}

/** C-end 兑换单。status: 0 待发放 / 1 已发放 / 2 已取消；redeemCode 仅 status=1 时可见。 */
export interface PointsExchange {
  id: number
  productId: number
  productName: string
  pointsCost: number
  quantity: number
  status: number
  statusText: string
  redeemCode: string
  remark: string
  fulfilledAt: string
  createdAt: string
}
