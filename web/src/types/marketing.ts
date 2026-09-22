import type { PageResult } from './browse'

/** 领券中心的一张可领取券。 */
export interface CouponCenterItem {
  templateId: number
  name: string
  type: number
  typeText: string
  thresholdAmount: number
  discountAmount: number
  currency: string
  shopId: number
  perUserLimit: number
  validDays: number
  claimed: boolean
  soldOut: boolean
  claimable: boolean
}

/** 用户钱包里的一张营销券。 */
export interface UserCoupon {
  id: number
  templateId: number
  name: string
  type: number
  typeText: string
  thresholdAmount: number
  discountAmount: number
  currency: string
  shopId: number
  status: number
  statusText: string
  expireAt?: string
  usedAt?: string
}

export type UserCouponPage = PageResult<UserCoupon>
