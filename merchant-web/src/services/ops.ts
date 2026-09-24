import { apiGet, apiPost } from '@/lib/http'
import type { PageResult } from '@/services/merchant'

export interface MerchantTicket {
  id: number
  shopId: number
  shopName: string
  subject: string
  content: string
  status: number
  statusText: string
  createdAt?: string
  messages?: { id: number; senderType: number; content: string; createdAt?: string }[]
}

export interface MerchantCoupon {
  id: number
  name: string
  type: number
  thresholdAmount: number
  discountAmount: number
  currency: string
  shopId: number
  totalQuantity: number
  auditStatus: number
  rejectReason: string
  status: number
}

export interface MerchantSeckill {
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
  auditStatus: number
  rejectReason: string
  status: number
}

export interface MerchantGroupBuy {
  id: number
  shopId: number
  dealId: number
  title: string
  groupPrice: number
  currency: string
  groupSize: number
  auditStatus: number
  rejectReason: string
  status: number
}

export interface TrendPoint {
  date: string
  views: number
  orders: number
  amount: number
}

export interface AdReportCampaign {
  id: number
  shopId: number
  name: string
  status: number
  auditStatus: number
  totalSpent: number
  spentToday: number
  clickCount: number
  clickCost: number
}

export function fetchMerchantTickets(page = 1, pageSize = 20) {
  return apiGet<PageResult<MerchantTicket>>('/api/b/v1/tickets', { page, pageSize })
}

export function createMerchantTicket(payload: { subject: string; content: string; shopId: number }) {
  return apiPost<MerchantTicket>('/api/b/v1/tickets', payload)
}

export function replyMerchantTicket(id: number, content: string) {
  return apiPost<MerchantTicket>(`/api/b/v1/tickets/${id}/messages`, { content })
}

export function fetchMerchantCoupons() {
  return apiGet<MerchantCoupon[]>('/api/b/v1/marketing/coupons')
}

export function createMerchantCoupon(payload: {
  name: string
  type: number
  thresholdAmount: number
  discountAmount: number
  shopId: number
  totalQuantity: number
  perUserLimit: number
  validDays: number
}) {
  return apiPost<MerchantCoupon>('/api/b/v1/marketing/coupons', payload)
}

export function fetchMerchantSeckill(shopId: number) {
  return apiGet<MerchantSeckill[]>('/api/b/v1/marketing/seckill', { shopId })
}

export function createMerchantSeckill(payload: {
  shopId: number
  dealId: number
  title: string
  seckillPrice: number
  stock: number
  startAt: string
  endAt: string
}) {
  return apiPost<MerchantSeckill>('/api/b/v1/marketing/seckill', payload)
}

export function fetchMerchantGroupBuy(shopId: number) {
  return apiGet<MerchantGroupBuy[]>('/api/b/v1/marketing/groupbuy', { shopId })
}

export function createMerchantGroupBuy(payload: {
  shopId: number
  dealId: number
  title: string
  groupPrice: number
  groupSize: number
  startAt: string
  endAt: string
}) {
  return apiPost<MerchantGroupBuy>('/api/b/v1/marketing/groupbuy', payload)
}

export function fetchTrend(shopId: number, days = 7) {
  return apiGet<{ shopId: number; days: number; list: TrendPoint[] }>('/api/b/v1/analytics/trend', { shopId, days })
}

export function exportTrend(shopId: number, days = 7) {
  return apiGet<string>('/api/b/v1/analytics/export', { shopId, days })
}

export function fetchAdReport(shopId: number) {
  return apiGet<{ shopId: number; campaigns: AdReportCampaign[] }>('/api/b/v1/ads/report', { shopId })
}
