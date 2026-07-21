import { apiDelete, apiGet, apiPost, apiPut } from '@/lib/http'
import type {
  AdminAuditTask,
  AdminAuditLog,
  AdminOrder,
  AdminBanner,
  AdminBannerPayload,
  AdminHotWord,
  AdminHotWordPayload,
  AdminOperationActivity,
  AdminOperationActivityItem,
  AdminOperationActivityItemPayload,
  AdminOperationActivityPayload,
  AdminPrivacyTask,
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

export interface AdminPrivacyTaskQuery {
  userId?: number
  taskType?: number
  status?: number
  keyword?: string
  page?: number
  pageSize?: number
}

export interface AdminOrderQuery {
  merchantId?: number
  shopId?: number
  userId?: number
  payStatus?: number
  refundStatus?: number
  orderNo?: string
  dateFrom?: string
  dateTo?: string
  page?: number
  pageSize?: number
}

export interface AdminBannerQuery {
  cityId?: number
}

export interface AdminOperationActivityQuery {
  cityId?: number
  status?: number
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

export function listAdminPrivacyTasks(query: AdminPrivacyTaskQuery) {
  return apiGet<PageResult<AdminPrivacyTask>>('/api/admin/v1/privacy/tasks', query)
}

export function listAdminOrders(query: AdminOrderQuery) {
  return apiGet<PageResult<AdminOrder>>('/api/admin/v1/orders', query)
}

export function listAdminBanners(query?: AdminBannerQuery) {
  return apiGet<AdminBanner[]>('/api/admin/v1/banners', query)
}

export function createAdminBanner(payload: AdminBannerPayload) {
  return apiPost<AdminBanner>('/api/admin/v1/banners', payload)
}

export function updateAdminBanner(bannerId: number, payload: AdminBannerPayload) {
  return apiPut<AdminBanner>(`/api/admin/v1/banners/${bannerId}`, payload)
}

export function updateAdminBannerStatus(bannerId: number, enabled: boolean) {
  return apiPut<AdminBanner>(`/api/admin/v1/banners/${bannerId}/status`, { enabled })
}

export function removeAdminBanner(bannerId: number) {
  return apiDelete<void>(`/api/admin/v1/banners/${bannerId}`)
}

export function listAdminHotWords() {
  return apiGet<AdminHotWord[]>('/api/admin/v1/search/hotwords')
}

export function createAdminHotWord(payload: AdminHotWordPayload) {
  return apiPost<AdminHotWord>('/api/admin/v1/search/hotwords', payload)
}

export function updateAdminHotWord(hotWordId: number, payload: AdminHotWordPayload) {
  return apiPut<AdminHotWord>(`/api/admin/v1/search/hotwords/${hotWordId}`, payload)
}

export function updateAdminHotWordStatus(hotWordId: number, enabled: boolean) {
  return apiPut<AdminHotWord>(`/api/admin/v1/search/hotwords/${hotWordId}/status`, { enabled })
}

export function removeAdminHotWord(hotWordId: number) {
  return apiDelete<void>(`/api/admin/v1/search/hotwords/${hotWordId}`)
}

export function listAdminOperationActivities(query?: AdminOperationActivityQuery) {
  return apiGet<AdminOperationActivity[]>('/api/admin/v1/operations/activities', query)
}

export function createAdminOperationActivity(payload: AdminOperationActivityPayload) {
  return apiPost<AdminOperationActivity>('/api/admin/v1/operations/activities', payload)
}

export function updateAdminOperationActivity(activityId: number, payload: AdminOperationActivityPayload) {
  return apiPut<AdminOperationActivity>(`/api/admin/v1/operations/activities/${activityId}`, payload)
}

export function updateAdminOperationActivityStatus(activityId: number, status: number) {
  return apiPut<AdminOperationActivity>(`/api/admin/v1/operations/activities/${activityId}/status`, { status })
}

export function removeAdminOperationActivity(activityId: number) {
  return apiDelete<void>(`/api/admin/v1/operations/activities/${activityId}`)
}

export function listAdminOperationActivityItems(activityId: number) {
  return apiGet<AdminOperationActivityItem[]>(`/api/admin/v1/operations/activities/${activityId}/items`)
}

export function createAdminOperationActivityItem(activityId: number, payload: AdminOperationActivityItemPayload) {
  return apiPost<AdminOperationActivityItem>(`/api/admin/v1/operations/activities/${activityId}/items`, payload)
}

export function updateAdminOperationActivityItem(
  activityId: number,
  itemId: number,
  payload: AdminOperationActivityItemPayload,
) {
  return apiPut<AdminOperationActivityItem>(`/api/admin/v1/operations/activities/${activityId}/items/${itemId}`, payload)
}

export function updateAdminOperationActivityItemStatus(activityId: number, itemId: number, status: number) {
  return apiPut<AdminOperationActivityItem>(`/api/admin/v1/operations/activities/${activityId}/items/${itemId}/status`, { status })
}

export function removeAdminOperationActivityItem(activityId: number, itemId: number) {
  return apiDelete<void>(`/api/admin/v1/operations/activities/${activityId}/items/${itemId}`)
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
