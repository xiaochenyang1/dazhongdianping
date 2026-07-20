import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
  apiDelete: vi.fn(),
}))

vi.mock('@/lib/http', () => mocks)

import * as adminService from './admin'

type RbacService = {
  fetchAdminMe: () => unknown
  listAdminPermissions: () => unknown
  listAdminRoles: () => unknown
  createAdminRole: (payload: object) => unknown
  updateAdminRole: (roleId: number, payload: object) => unknown
  updateAdminRoleStatus: (roleId: number, status: number) => unknown
  removeAdminRole: (roleId: number) => unknown
  listAdminAccounts: (params: object) => unknown
  createAdminAccount: (payload: object) => unknown
  updateAdminAccount: (adminId: number, payload: object) => unknown
  updateAdminAccountStatus: (adminId: number, status: number) => unknown
  resetAdminAccountPassword: (adminId: number, password: string) => unknown
}

const rbac = adminService as unknown as RbacService

describe('admin RBAC service', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
  })

  it('uses the database identity and RBAC endpoint contracts', () => {
    expect(rbac.fetchAdminMe).toBeTypeOf('function')
    expect(rbac.listAdminPermissions).toBeTypeOf('function')
    expect(rbac.listAdminRoles).toBeTypeOf('function')

    rbac.fetchAdminMe()
    rbac.listAdminPermissions()
    rbac.listAdminRoles()
    rbac.createAdminRole({ code: 'eu_reader', name: 'EU 只读', description: '', permissionIds: [14] })
    rbac.updateAdminRole(9, { code: 'eu_reader', name: 'EU 只读', description: '', permissionIds: [14] })
    rbac.updateAdminRoleStatus(9, 2)
    rbac.removeAdminRole(9)
    rbac.listAdminAccounts({ page: 1, pageSize: 20 })
    rbac.createAdminAccount({ account: 'eu.reader', password: 'Reader#123456', name: 'EU 只读员', roleIds: [9], regions: ['EU'] })
    rbac.updateAdminAccount(7, { name: 'EU 新名称', roleIds: [9], regions: ['EU'] })
    rbac.updateAdminAccountStatus(7, 2)
    rbac.resetAdminAccountPassword(7, 'Reader#654321')

    expect(mocks.apiGet).toHaveBeenCalledWith('/api/admin/v1/auth/me')
    expect(mocks.apiGet).toHaveBeenCalledWith('/api/admin/v1/rbac/permissions')
    expect(mocks.apiGet).toHaveBeenCalledWith('/api/admin/v1/rbac/roles')
    expect(mocks.apiPost).toHaveBeenCalledWith('/api/admin/v1/rbac/roles', { code: 'eu_reader', name: 'EU 只读', description: '', permissionIds: [14] })
    expect(mocks.apiPut).toHaveBeenCalledWith('/api/admin/v1/rbac/roles/9', { code: 'eu_reader', name: 'EU 只读', description: '', permissionIds: [14] })
    expect(mocks.apiPut).toHaveBeenCalledWith('/api/admin/v1/rbac/roles/9/status', { status: 2 })
    expect(mocks.apiDelete).toHaveBeenCalledWith('/api/admin/v1/rbac/roles/9')
    expect(mocks.apiGet).toHaveBeenCalledWith('/api/admin/v1/rbac/admins', { page: 1, pageSize: 20 })
    expect(mocks.apiPost).toHaveBeenCalledWith('/api/admin/v1/rbac/admins', { account: 'eu.reader', password: 'Reader#123456', name: 'EU 只读员', roleIds: [9], regions: ['EU'] })
    expect(mocks.apiPut).toHaveBeenCalledWith('/api/admin/v1/rbac/admins/7', { name: 'EU 新名称', roleIds: [9], regions: ['EU'] })
    expect(mocks.apiPut).toHaveBeenCalledWith('/api/admin/v1/rbac/admins/7/status', { status: 2 })
    expect(mocks.apiPut).toHaveBeenCalledWith('/api/admin/v1/rbac/admins/7/password', { password: 'Reader#654321' })
  })
})
