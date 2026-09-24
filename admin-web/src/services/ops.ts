import { apiGet, apiPost, apiPut } from '@/lib/http'
import type { PageResult } from '@/types/admin'

export interface OpsTicket {
  id: number
  requesterType: number
  requesterId: number
  shopId: number
  shopName: string
  subject: string
  content: string
  status: number
  statusText: string
  createdAt?: string
  messages?: { id: number; senderType: number; senderId: number; content: string; createdAt?: string }[]
}

export interface OpsGuide {
  id: number
  cityId: number
  title: string
  summary: string
  coverUrl: string
  status: number
  createdAt?: string
  sections?: { id?: number; heading: string; body: string; shopId: number; sortNo: number }[]
}

export interface OpsCreatorTask {
  id: number
  title: string
  description: string
  rewardPoints: number
  status: number
  createdAt?: string
}

export interface OpsFlag {
  id: number
  flagKey: string
  description: string
  enabled: boolean
  rolloutPercent: number
}

export interface OpsExperiment {
  id: number
  name: string
  flagKey: string
  status: number
  createdAt?: string
}

export interface OpsInvoice {
  id: number
  userId: number
  orderId: number
  amount: number
  taxAmount: number
  currency: string
  status: number
  statusText: string
  invoiceNo: string
  rejectReason: string
  createdAt?: string
}

export interface OpsTaxRate {
  id: number
  region: string
  name: string
  rateBp: number
  status: number
}

export interface OpsAutomodHit {
  id: number
  bizType: string
  bizId: number
  userId: number
  decision: number
  provider: string
  reason: string
  createdAt?: string
}

export interface OpsOpenApp {
  id: number
  name: string
  ownerMerchantId: number
  region: string
  status: number
  createdAt?: string
  keyIds: string[]
  keyId?: string
  secret?: string
}

export function fetchAdminTickets(params: { status?: number; page?: number; pageSize?: number } = {}) {
  return apiGet<PageResult<OpsTicket>>('/api/admin/v1/tickets', params)
}

export function fetchAdminTicket(id: number) {
  return apiGet<OpsTicket>(`/api/admin/v1/tickets/${id}`)
}

export function replyAdminTicket(id: number, content: string) {
  return apiPost<OpsTicket>(`/api/admin/v1/tickets/${id}/reply`, { content })
}

export function updateAdminTicketStatus(id: number, status: number) {
  return apiPost<OpsTicket>(`/api/admin/v1/tickets/${id}/status`, { status })
}

export function fetchAdminGuides(page = 1, pageSize = 20) {
  return apiGet<PageResult<OpsGuide>>('/api/admin/v1/guides', { page, pageSize })
}

export function saveAdminGuide(payload: {
  title: string
  summary: string
  coverUrl: string
  cityId: number
  status: number
  sections: { heading: string; body: string; shopId: number; sortNo: number }[]
}, id?: number) {
  return id
    ? apiPut<OpsGuide>(`/api/admin/v1/guides/${id}`, payload)
    : apiPost<OpsGuide>('/api/admin/v1/guides', payload)
}

export function updateAdminGuideStatus(id: number, status: number) {
  return apiPost<OpsGuide>(`/api/admin/v1/guides/${id}/status`, { status })
}

export function fetchAdminCreatorTasks(page = 1, pageSize = 20) {
  return apiGet<PageResult<OpsCreatorTask>>('/api/admin/v1/creator/tasks', { page, pageSize })
}

export function saveAdminCreatorTask(payload: {
  title: string
  description: string
  rewardPoints: number
  status: number
}, id?: number) {
  return id
    ? apiPut<OpsCreatorTask>(`/api/admin/v1/creator/tasks/${id}`, payload)
    : apiPost<OpsCreatorTask>('/api/admin/v1/creator/tasks', payload)
}

export function fetchAdminFlags() {
  return apiGet<OpsFlag[]>('/api/admin/v1/flags')
}

export function saveAdminFlag(payload: {
  flagKey: string
  description: string
  enabled: boolean
  rolloutPercent: number
}, id?: number) {
  return id
    ? apiPut<OpsFlag>(`/api/admin/v1/flags/${id}`, payload)
    : apiPost<OpsFlag>('/api/admin/v1/flags', payload)
}

export function fetchAdminExperiments() {
  return apiGet<OpsExperiment[]>('/api/admin/v1/experiments')
}

export function createAdminExperiment(payload: { name: string; flagKey: string; status: number }) {
  return apiPost<OpsExperiment>('/api/admin/v1/experiments', payload)
}

export function fetchAdminInvoices(page = 1, pageSize = 20) {
  return apiGet<PageResult<OpsInvoice>>('/api/admin/v1/invoices', { page, pageSize })
}

export function issueAdminInvoice(id: number, invoiceNo: string) {
  return apiPost<OpsInvoice>(`/api/admin/v1/invoices/${id}/issue`, { invoiceNo })
}

export function rejectAdminInvoice(id: number, reason: string) {
  return apiPost<OpsInvoice>(`/api/admin/v1/invoices/${id}/reject`, { reason })
}

export function fetchAdminTaxRates() {
  return apiGet<OpsTaxRate[]>('/api/admin/v1/tax-rates')
}

export function updateAdminTaxRate(id: number, payload: { name: string; rateBp: number; status: number }) {
  return apiPut<OpsTaxRate>(`/api/admin/v1/tax-rates/${id}`, payload)
}

export function fetchAutomodHits(params: { decision?: number; page?: number; pageSize?: number } = {}) {
  return apiGet<PageResult<OpsAutomodHit>>('/api/admin/v1/automod/hits', params)
}

export function fetchOpenApps() {
  return apiGet<OpsOpenApp[]>('/api/admin/v1/openapi/apps')
}

export function createOpenApp(payload: { name: string; ownerMerchantId: number }) {
  return apiPost<OpsOpenApp>('/api/admin/v1/openapi/apps', payload)
}

export function updateOpenAppStatus(id: number, status: number) {
  return apiPost<OpsOpenApp>(`/api/admin/v1/openapi/apps/${id}/status`, { status })
}

export function auditCouponTemplate(id: number, approve: boolean, reason: string) {
  return apiPost<Record<string, unknown>>(`/api/admin/v1/marketing/coupon-templates/${id}/audit`, { approve, reason })
}

export interface AdminCampaign {
  id: number
  shopId: number
  title: string
  auditStatus: number
  status: number
  rejectReason: string
  currency: string
  seckillPrice?: number
  groupPrice?: number
  stock?: number
  sold?: number
  groupSize?: number
  startAt?: string
  endAt?: string
}

export function fetchAdminSeckills() {
  return apiGet<AdminCampaign[]>('/api/admin/v1/marketing/seckill')
}

export function fetchAdminGroupBuys() {
  return apiGet<AdminCampaign[]>('/api/admin/v1/marketing/groupbuy')
}

export function auditSeckill(id: number, approve: boolean, reason: string) {
  return apiPost<Record<string, unknown>>(`/api/admin/v1/marketing/seckill/${id}/audit`, { approve, reason })
}

export function auditGroupBuy(id: number, approve: boolean, reason: string) {
  return apiPost<Record<string, unknown>>(`/api/admin/v1/marketing/groupbuy/${id}/audit`, { approve, reason })
}
