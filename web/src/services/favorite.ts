import { apiDelete, apiGet, apiPost } from '@/lib/http'
import type { FavoriteItem, FavoritePage } from '@/types/favorite'

export function addFavorite(targetType: number, targetId: number) {
  return apiPost<FavoriteItem>('/api/c/v1/favorites', { targetType, targetId })
}

export function removeFavorite(targetType: number, targetId: number) {
  return apiDelete<void>('/api/c/v1/favorites', { targetType, targetId })
}

export function fetchFavorites(targetType?: number, page = 1, pageSize = 12) {
  return apiGet<FavoritePage>('/api/c/v1/favorites', { targetType, page, pageSize })
}
