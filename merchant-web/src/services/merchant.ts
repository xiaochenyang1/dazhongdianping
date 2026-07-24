import { apiGet, apiPost, apiPut } from '@/lib/http'
import type { MerchantRegion } from '@/composables/useMerchantSession'

export interface PageResult<T> { list: T[]; total: number; page: number; pageSize: number; hasMore: boolean }
export interface MerchantLogin { accessToken: string; tokenType: string; merchantId: number; account: string }
export interface MerchantRegistrationPayload {
  account: string
  password: string
  companyName: string
  contactName: string
  contactPhone: string
  region: MerchantRegion
}
export interface MerchantRegistrationResult extends MerchantLogin { operatorId: number; auditStatus: number }
export interface SettlementPayload { licenseUrl: string; legalPerson: string; shopPhotoUrls: string[] }
export interface SettlementStatus extends SettlementPayload {
  merchantId: number
  status: -1 | 0 | 1 | 2
  statusText: string
  rejectReason?: string
  submittedAt?: string
  auditedAt?: string
}
export interface MerchantRole { id: number; code: string; name: string; permissions: string[] }
export interface MerchantAccount {
  merchant: { id: number; companyName: string; region: MerchantRegion }
  operator: { id: number; type: 'owner' | 'staff'; name: string }
  permissions: string[]
}
export interface MerchantStaff {
  id: number
  account: string
  name: string
  status: number
  roles: Array<Pick<MerchantRole, 'id' | 'code' | 'name'>>
  shopScopeType: 1 | 2
  shopIds: number[]
}
export interface MerchantStaffPayload {
  account?: string
  password?: string
  name: string
  phone: string
  email: string
  roleIds: number[]
  shopScopeType: 1 | 2
  shopIds: number[]
}
export interface MerchantShopOption { id: number; name: string }
export interface MerchantOrderRefund {
  id?: number
  amount?: number
  reason?: string
  status: number
  statusText: string
}
export interface MerchantOrder {
  id: number
  orderNo: string
  shopName: string
  amount: number
  currency: string
  payStatus: number
  payStatusText: string
  refund?: MerchantOrderRefund
}
export interface MerchantReviewReply { id: number; content: string; updatedAt?: string }
export interface MerchantReviewAppeal { id: number; status: number; statusText: string }
export interface MerchantReview {
  id: number
  shopId: number
  shopName: string
  userId: number
  userName: string
  content: string
  scoreOverall: number
  createdAt: string
  merchantReply?: MerchantReviewReply | null
  appeal?: MerchantReviewAppeal | null
}
export interface MerchantReservation {
  id: number
  reservationNo: string
  shop: { id: number; name: string }
  reserveTime: string
  status: number
  statusText: string
  canConfirm: boolean
  canReject: boolean
}
export interface MerchantCoupon {
  id: number
  code: string
  dealId: number
  dealTitle: string
  shopId: number
  shopName: string
  status: number
  statusText?: string
  verifyAt?: string
  verifyBy?: number
  expireAt?: string
}

export function loginMerchant(payload: { account: string; password: string }) { return apiPost<MerchantLogin>('/api/b/v1/auth/login', payload) }
export function registerMerchant(payload: MerchantRegistrationPayload) { return apiPost<MerchantRegistrationResult>('/api/b/v1/auth/register', payload) }
export function fetchSettlementStatus() { return apiGet<SettlementStatus>('/api/b/v1/settle/status') }
export function submitSettlement(payload: SettlementPayload) { return apiPost<SettlementStatus>('/api/b/v1/settle/apply', payload) }
export function fetchAccount() { return apiGet<MerchantAccount>('/api/b/v1/account/me') }
export function fetchRoles() { return apiGet<{ list: MerchantRole[] }>('/api/b/v1/roles') }
export function fetchDashboard(params?: { shopId?: number; dateFrom?: string; dateTo?: string }) { return apiGet<Record<string, unknown>>('/api/b/v1/dashboard', params) }
export function fetchShops(params?: object) { return apiGet<PageResult<MerchantShopOption & Record<string, unknown>>>('/api/b/v1/shops', params) }
export function fetchStaffs(params?: { page?: number; pageSize?: number }) { return apiGet<PageResult<MerchantStaff>>('/api/b/v1/staffs', params) }
export function createStaff(payload: MerchantStaffPayload & { account: string; password: string }) { return apiPost<MerchantStaff>('/api/b/v1/staffs', payload) }
export function updateStaff(id: number, payload: MerchantStaffPayload) { return apiPut<MerchantStaff>(`/api/b/v1/staffs/${id}`, payload) }
export function updateStaffStatus(id: number, status: 1 | 2) { return apiPut<MerchantStaff>(`/api/b/v1/staffs/${id}/status`, { status }) }
export function fetchReservations(params?: object) { return apiGet<PageResult<MerchantReservation>>('/api/b/v1/reservations', params) }
export function confirmReservation(id: number) { return apiPost<Record<string, unknown>>(`/api/b/v1/reservations/${id}/confirm`) }
export function rejectReservation(id: number, reason: string) { return apiPost<Record<string, unknown>>(`/api/b/v1/reservations/${id}/reject`, { reason }) }
export function fetchDeals(params?: object) { return apiGet<PageResult<Record<string, unknown>>>('/api/b/v1/deals', params) }
export function updateDealStatus(id: number, status: number) { return apiPut<Record<string, unknown>>(`/api/b/v1/deals/${id}/status`, { status }) }
export function fetchOrders(params?: object) { return apiGet<PageResult<MerchantOrder>>('/api/b/v1/orders', params) }
export function auditRefund(id: number, decision: 'approve' | 'reject', reason: string) {
  return apiPost<Record<string, unknown>>(`/api/b/v1/orders/${id}/refund-audit`, { decision, reason })
}
export function verifyCoupon(code: string) {
  const normalized = code.trim()
  return apiPost<MerchantCoupon>(`/api/b/v1/coupons/${encodeURIComponent(normalized)}/verify`)
}
export function fetchReviews(params?: object) { return apiGet<PageResult<MerchantReview>>('/api/b/v1/reviews', params) }
export function saveReply(id: number, content: string) { return apiPut<Record<string, unknown>>(`/api/b/v1/reviews/${id}/reply`, { content }) }
export function createAppealDraft(id: number) { return apiPost<Record<string, unknown>>(`/api/b/v1/reviews/${id}/appeal-drafts`) }
export function saveAppeal(id: number, payload: { reason: string; evidenceUrls: string[] }) { return apiPut<Record<string, unknown>>(`/api/b/v1/review-appeals/${id}`, payload) }
export function submitAppeal(id: number) { return apiPost<Record<string, unknown>>(`/api/b/v1/review-appeals/${id}/submit`) }
export function regionLabel(region: MerchantRegion) { return region === 'EU' ? '欧洲区' : '国内区' }
