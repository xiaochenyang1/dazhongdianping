import { apiDelete, apiGet } from '@/lib/http'
import type { ShopBrowseHistoryPage } from '@/types/browse-history'

export function fetchBrowseHistory(page = 1, pageSize = 20) {
  return apiGet<ShopBrowseHistoryPage>('/api/c/v1/user/browse-history', { page, pageSize })
}

export function clearBrowseHistory() {
  return apiDelete<void>('/api/c/v1/user/browse-history')
}

export function removeBrowseHistoryItem(shopId: number) {
  return apiDelete<void>(`/api/c/v1/user/browse-history/${shopId}`)
}
