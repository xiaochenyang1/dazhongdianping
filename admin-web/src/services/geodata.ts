import { apiDelete, apiGet, apiPost, apiPut } from '@/lib/http'
import type {
  AdminGeoArea,
  AdminGeoCategory,
  AdminGeoCity,
  GeoAreaPayload,
  GeoCategoryPayload,
  GeoCityPayload,
} from '@/types/admin'

export const listGeoCategories = () =>
  apiGet<AdminGeoCategory[]>('/api/admin/v1/categories')

export const createGeoCategory = (payload: GeoCategoryPayload) =>
  apiPost<AdminGeoCategory>('/api/admin/v1/categories', payload)

export const updateGeoCategory = (id: number, payload: GeoCategoryPayload) =>
  apiPut<AdminGeoCategory>(`/api/admin/v1/categories/${id}`, payload)

export const updateGeoCategoryStatus = (id: number, status: number) =>
  apiPut<AdminGeoCategory>(`/api/admin/v1/categories/${id}/status`, { status })

export const removeGeoCategory = (id: number) =>
  apiDelete<void>(`/api/admin/v1/categories/${id}`)

export const listGeoCities = () =>
  apiGet<AdminGeoCity[]>('/api/admin/v1/cities')

export const createGeoCity = (payload: GeoCityPayload) =>
  apiPost<AdminGeoCity>('/api/admin/v1/cities', payload)

export const updateGeoCity = (id: number, payload: GeoCityPayload) =>
  apiPut<AdminGeoCity>(`/api/admin/v1/cities/${id}`, payload)

export const updateGeoCityStatus = (id: number, status: number) =>
  apiPut<AdminGeoCity>(`/api/admin/v1/cities/${id}/status`, { status })

export const removeGeoCity = (id: number) =>
  apiDelete<void>(`/api/admin/v1/cities/${id}`)

export const listGeoAreas = (cityId: number) =>
  apiGet<AdminGeoArea[]>('/api/admin/v1/areas', { cityId })

export const createGeoArea = (payload: GeoAreaPayload) =>
  apiPost<AdminGeoArea>('/api/admin/v1/areas', payload)

export const updateGeoArea = (id: number, payload: GeoAreaPayload) =>
  apiPut<AdminGeoArea>(`/api/admin/v1/areas/${id}`, payload)

export const updateGeoAreaStatus = (id: number, status: number) =>
  apiPut<AdminGeoArea>(`/api/admin/v1/areas/${id}/status`, { status })

export const removeGeoArea = (id: number) =>
  apiDelete<void>(`/api/admin/v1/areas/${id}`)
