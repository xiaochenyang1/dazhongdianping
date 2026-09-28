import { apiGet, apiPost } from '@/lib/http'
import type { WaitlistEntry, WaitlistJoinPayload } from '@/types/waitlist'

/** 取号（需登录）。 */
export function joinWaitlist(shopId: number, payload: WaitlistJoinPayload) {
  return apiPost<WaitlistEntry>(`/api/c/v1/shops/${shopId}/waitlist`, payload)
}

/** 我的进行中排队。 */
export function fetchMyWaitlist() {
  return apiGet<WaitlistEntry[]>('/api/c/v1/waitlist/mine')
}

/** 取消排队。 */
export function cancelWaitlist(id: number) {
  return apiPost<WaitlistEntry>(`/api/c/v1/waitlist/${id}/cancel`)
}
