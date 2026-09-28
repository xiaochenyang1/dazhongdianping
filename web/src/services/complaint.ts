import { apiGet, apiPost } from '@/lib/http'
import type { ComplaintCreatePayload, ComplaintPage, ComplaintTicket } from '@/types/complaint'

/** 发起投诉（需登录）。 */
export function createComplaint(payload: ComplaintCreatePayload) {
  return apiPost<ComplaintTicket>('/api/c/v1/complaints', payload)
}

/** 我的投诉列表。 */
export function fetchMyComplaints(status?: number, page = 1, pageSize = 20) {
  return apiGet<ComplaintPage>('/api/c/v1/complaints', { status, page, pageSize })
}

/** 投诉详情（含处理日志）。 */
export function fetchComplaint(id: number) {
  return apiGet<ComplaintTicket>(`/api/c/v1/complaints/${id}`)
}
