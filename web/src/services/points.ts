import { apiGet, apiPost } from '@/lib/http'
import type { PageResult } from '@/types/browse'
import type { PointsExchange, PointsProduct } from '@/types/points'

export function fetchPointsProducts(query?: { page?: number; pageSize?: number }) {
  return apiGet<PageResult<PointsProduct>>('/api/c/v1/points/products', query)
}

export function fetchPointsProduct(productId: number) {
  return apiGet<PointsProduct>(`/api/c/v1/points/products/${productId}`)
}

export function exchangePointsProduct(productId: number) {
  return apiPost<PointsExchange>(`/api/c/v1/points/products/${productId}/exchange`)
}

export function fetchMyPointsExchanges(query?: { page?: number; pageSize?: number }) {
  return apiGet<PageResult<PointsExchange>>('/api/c/v1/points/exchanges', query)
}
