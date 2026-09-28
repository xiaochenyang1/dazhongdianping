import { apiGet, apiPost } from '@/lib/http'
import type { CouponCenterItem, UserCoupon, UserCouponPage } from '@/types/marketing'

/** 领券中心：当前区域可领取的券（匿名可看，登录后带领取状态）。 */
export function fetchCouponCenter() {
  return apiGet<CouponCenterItem[]>('/api/c/v1/marketing/coupons/center')
}

/** 领取一张券（需登录）。 */
export function claimCoupon(templateId: number) {
  return apiPost<UserCoupon>(`/api/c/v1/marketing/coupons/${templateId}/claim`)
}

/** 我的营销券钱包。 */
export function fetchMyCoupons(status?: number, page = 1, pageSize = 50) {
  return apiGet<UserCouponPage>('/api/c/v1/marketing/coupons/mine', { status, page, pageSize })
}

/** 下单前预览：某团购按数量可用的营销券。 */
export function fetchUsableCoupons(dealId: number, quantity: number) {
  return apiGet<UserCoupon[]>(`/api/c/v1/deals/${dealId}/usable-coupons`, { quantity })
}
