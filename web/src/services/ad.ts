import { apiGet, apiPost } from '@/lib/http'
import type { AdSlot } from '@/types/ad'

/** 固定广告位召回。slotType 1=搜索(带 keyword) 2=首页/列表。匿名可用。 */
export function fetchAdSlots(slotType: number, keyword?: string, limit = 3) {
  return apiGet<AdSlot[]>('/api/c/v1/ads', { slotType, keyword, limit })
}

/** 广告点击上报计费（失败不影响跳转）。 */
export function reportAdClick(campaignId: number) {
  return apiPost<{ charged: boolean }>(`/api/c/v1/ads/${campaignId}/click`)
}
