import { apiDelete, apiGet, apiPost, apiPut } from '@/lib/http'
import type {
  AdminAuditTask,
  AdminAuditLog,
  AdminImportBatch,
  AdminImportPayload,
  AdminImportResult,
  AdminIdentity,
  AdminLoginResponse,
  AdminMenuItem,
  AdminPermissionItem,
  AdminRole,
  AdminRolePayload,
  AdminAccount,
  AdminAccountCreatePayload,
  AdminAccountUpdatePayload,
  AdminShopDetail,
  AdminShopSavePayload,
  AdminShopSummary,
  PageResult,
  Region,
  RankConfig,
  RankConfigPayload,
  RankPublishResult,
  GrowthConfig,
  GrowthRule,
  GrowthRulePayload,
  LevelConfig,
  AdminMerchantApplication,
} from '@/types/admin'

export interface AdminShopQuery {
  region?: Region
  cityId?: number
  areaId?: number
  categoryId?: number
  keyword?: string
  page?: number
  pageSize?: number
}

export interface AdminImportBatchQuery {
  region?: Region
  status?: number
  page?: number
  pageSize?: number
}

export interface AdminAuditTaskQuery {
  region?: Region
  bizType?: number
  status?: number
  page?: number
  pageSize?: number
}

export interface AdminAuditLogQuery {
  adminId?: number
  action?: string
  target?: string
  keyword?: string
  page?: number
  pageSize?: number
}

export function loginAdmin(payload: { account: string; password: string }) {
  return apiPost<AdminLoginResponse>('/api/admin/v1/auth/login', payload)
}

export function logoutAdmin(): Promise<void> {
  return apiPost<void>('/api/admin/v1/auth/logout')
}

export function fetchAdminMe() {
  return apiGet<AdminIdentity>('/api/admin/v1/auth/me')
}

export function fetchAdminMenus() {
  return apiGet<AdminMenuItem[]>('/api/admin/v1/menus')
}

export function listAdminPermissions() {
  return apiGet<AdminPermissionItem[]>('/api/admin/v1/rbac/permissions')
}

export function listAdminRoles() {
  return apiGet<AdminRole[]>('/api/admin/v1/rbac/roles')
}

export function createAdminRole(payload: AdminRolePayload) {
  return apiPost<AdminRole>('/api/admin/v1/rbac/roles', payload)
}

export function updateAdminRole(roleId: number, payload: AdminRolePayload) {
  return apiPut<AdminRole>(`/api/admin/v1/rbac/roles/${roleId}`, payload)
}

export function updateAdminRoleStatus(roleId: number, status: number) {
  return apiPut<AdminRole>(`/api/admin/v1/rbac/roles/${roleId}/status`, { status })
}

export function removeAdminRole(roleId: number) {
  return apiDelete<void>(`/api/admin/v1/rbac/roles/${roleId}`)
}

export function listAdminAccounts(params: { page?: number; pageSize?: number }) {
  return apiGet<PageResult<AdminAccount>>('/api/admin/v1/rbac/admins', params)
}

export function createAdminAccount(payload: AdminAccountCreatePayload) {
  return apiPost<AdminAccount>('/api/admin/v1/rbac/admins', payload)
}

export function updateAdminAccount(adminId: number, payload: AdminAccountUpdatePayload) {
  return apiPut<AdminAccount>(`/api/admin/v1/rbac/admins/${adminId}`, payload)
}

export function updateAdminAccountStatus(adminId: number, status: number) {
  return apiPut<AdminAccount>(`/api/admin/v1/rbac/admins/${adminId}/status`, { status })
}

export function resetAdminAccountPassword(adminId: number, password: string) {
  return apiPut<void>(`/api/admin/v1/rbac/admins/${adminId}/password`, { password })
}

export function listShops(query: AdminShopQuery) {
  return apiGet<PageResult<AdminShopSummary>>('/api/admin/v1/shops', query)
}

export function getShop(shopId: number) {
  return apiGet<AdminShopDetail>(`/api/admin/v1/shops/${shopId}`)
}

export function createShop(payload: AdminShopSavePayload) {
  return apiPost<AdminShopDetail>('/api/admin/v1/shops', payload)
}

export function updateShop(shopId: number, payload: AdminShopSavePayload) {
  return apiPut<AdminShopDetail>(`/api/admin/v1/shops/${shopId}`, payload)
}

export function removeShop(shopId: number) {
  return apiDelete<void>(`/api/admin/v1/shops/${shopId}`)
}

export function importShops(payload: AdminImportPayload) {
  return apiPost<AdminImportResult>('/api/admin/v1/import/shops', payload)
}

export function listImportBatches(query: AdminImportBatchQuery) {
  return apiGet<PageResult<AdminImportBatch>>('/api/admin/v1/import/batches', query)
}

export function listAuditTasks(query: AdminAuditTaskQuery) {
  return apiGet<PageResult<AdminAuditTask>>('/api/admin/v1/audit/tasks', query)
}

export function listAdminAuditLogs(query: AdminAuditLogQuery) {
  return apiGet<PageResult<AdminAuditLog>>('/api/admin/v1/audit/logs', query)
}

export function passAuditTask(taskId: number, payload: { remark?: string }) {
  return apiPost<AdminAuditTask>(`/api/admin/v1/audit/tasks/${taskId}/pass`, payload)
}

export function rejectAuditTask(taskId: number, payload: { reason: string }) {
  return apiPost<AdminAuditTask>(`/api/admin/v1/audit/tasks/${taskId}/reject`, payload)
}

export function listMerchantApplications(query: { status?: number; page?: number; pageSize?: number }) {
  return apiGet<PageResult<AdminMerchantApplication>>('/api/admin/v1/merchant-applications', query)
}

export function auditMerchantApplication(merchantId: number, payload: { status: 1 | 2; reason: string }) {
  return apiPost<AdminMerchantApplication>(`/api/admin/v1/merchant-applications/${merchantId}/audit`, payload)
}

export function listRankConfigs() {
  return apiGet<RankConfig[]>('/api/admin/v1/ranks/config')
}

export function createRankConfig(payload: RankConfigPayload) {
  return apiPost<RankConfig>('/api/admin/v1/ranks/config', payload)
}

export function updateRankConfig(configId: number, payload: RankConfigPayload) {
  return apiPut<RankConfig>(`/api/admin/v1/ranks/config/${configId}`, payload)
}

export function publishRankConfig(configId: number) {
  return apiPost<RankPublishResult>(`/api/admin/v1/ranks/config/${configId}/publish`)
}

export function rollbackRankConfig(configId: number) {
  return apiPost<RankPublishResult>(`/api/admin/v1/ranks/config/${configId}/rollback`)
}

export function fetchGrowthConfig() { return apiGet<GrowthConfig>('/api/admin/v1/growth/rules') }
export function createGrowthRule(payload: GrowthRulePayload) { return apiPost<GrowthRule>('/api/admin/v1/growth/rules', payload) }
export function updateGrowthRule(id: number, payload: GrowthRulePayload) { return apiPut<GrowthRule>(`/api/admin/v1/growth/rules/${id}`, payload) }
export function updateLevelConfig(level: number, payload: Omit<LevelConfig, 'level' | 'updatedAt'>) { return apiPut<LevelConfig>(`/api/admin/v1/growth/rules/levels/${level}`, payload) }
