import { apiGet } from '@/lib/http'
import type { Area, CategoryNode, City } from '@/types/admin'

export function fetchCategories() {
  return apiGet<CategoryNode[]>('/api/c/v1/categories')
}

export function fetchCities() {
  return apiGet<City[]>('/api/c/v1/cities')
}

export function fetchAreas(cityId: number) {
  return apiGet<Area[]>(`/api/c/v1/cities/${cityId}/areas`)
}
