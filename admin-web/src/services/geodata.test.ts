import { beforeEach, describe, expect, it, vi } from 'vitest'
import { apiDelete, apiGet, apiPost, apiPut } from '@/lib/http'
import {
  createGeoArea,
  createGeoCategory,
  createGeoCity,
  listGeoAreas,
  listGeoCategories,
  listGeoCities,
  removeGeoArea,
  removeGeoCategory,
  removeGeoCity,
  updateGeoArea,
  updateGeoAreaStatus,
  updateGeoCategory,
  updateGeoCategoryStatus,
  updateGeoCity,
  updateGeoCityStatus,
} from './geodata'

vi.mock('@/lib/http', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
  apiDelete: vi.fn(),
}))

describe('admin geodata service', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('uses the category management endpoints', async () => {
    await listGeoCategories()
    expect(apiGet).toHaveBeenCalledWith('/api/admin/v1/categories')

    const payload = { parentId: 0, name: '美食', sortNo: 1 }
    await createGeoCategory(payload)
    expect(apiPost).toHaveBeenCalledWith('/api/admin/v1/categories', payload)

    await updateGeoCategory(100, payload)
    expect(apiPut).toHaveBeenCalledWith('/api/admin/v1/categories/100', payload)

    await updateGeoCategoryStatus(100, 0)
    expect(apiPut).toHaveBeenCalledWith('/api/admin/v1/categories/100/status', { status: 0 })

    await removeGeoCategory(100)
    expect(apiDelete).toHaveBeenCalledWith('/api/admin/v1/categories/100')
  })

  it('uses the city management endpoints', async () => {
    await listGeoCities()
    expect(apiGet).toHaveBeenCalledWith('/api/admin/v1/cities')

    const payload = { code: 'PAR', name: 'Paris', sortNo: 1 }
    await createGeoCity(payload)
    expect(apiPost).toHaveBeenCalledWith('/api/admin/v1/cities', payload)

    await updateGeoCity(101, payload)
    expect(apiPut).toHaveBeenCalledWith('/api/admin/v1/cities/101', payload)

    await updateGeoCityStatus(101, 0)
    expect(apiPut).toHaveBeenCalledWith('/api/admin/v1/cities/101/status', { status: 0 })

    await removeGeoCity(101)
    expect(apiDelete).toHaveBeenCalledWith('/api/admin/v1/cities/101')
  })

  it('passes cityId as a query parameter for area management', async () => {
    await listGeoAreas(101)
    expect(apiGet).toHaveBeenCalledWith('/api/admin/v1/areas', { cityId: 101 })

    const payload = { cityId: 101, name: 'Le Marais', sortNo: 1 }
    await createGeoArea(payload)
    expect(apiPost).toHaveBeenCalledWith('/api/admin/v1/areas', payload)

    await updateGeoArea(1011, payload)
    expect(apiPut).toHaveBeenCalledWith('/api/admin/v1/areas/1011', payload)

    await updateGeoAreaStatus(1011, 0)
    expect(apiPut).toHaveBeenCalledWith('/api/admin/v1/areas/1011/status', { status: 0 })

    await removeGeoArea(1011)
    expect(apiDelete).toHaveBeenCalledWith('/api/admin/v1/areas/1011')
  })
})
