import { apiGet, apiPost } from '@/lib/http'
import type { GroupBuyCampaign, GroupBuyTeam, SeckillEvent } from '@/types/campaign'

export function fetchSeckill() {
  return apiGet<SeckillEvent[]>('/api/c/v1/marketing/seckill')
}

export function claimSeckill(id: number) {
  return apiPost<{ claimId: number }>(`/api/c/v1/marketing/seckill/${id}/claim`)
}

export function fetchGroupBuy() {
  return apiGet<GroupBuyCampaign[]>('/api/c/v1/marketing/groupbuy')
}

export function openGroupTeam(id: number) {
  return apiPost<GroupBuyTeam>(`/api/c/v1/marketing/groupbuy/${id}/teams`)
}

export function joinGroupTeam(teamId: number) {
  return apiPost<GroupBuyTeam>(`/api/c/v1/marketing/groupbuy/teams/${teamId}/join`)
}
