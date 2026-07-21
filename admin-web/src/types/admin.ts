export type Region = 'CN' | 'EU'

export interface PageResult<T> {
  list: T[]
  total: number
  page: number
  pageSize: number
  hasMore: boolean
}

export interface AdminProfile {
  id: number
  account: string
  name: string
}

export interface AdminLoginResponse {
  accessToken: string
  tokenType: string
  profile: AdminProfile
  permissions: string[]
  regions: Region[]
}

export interface AdminIdentity {
  profile: AdminProfile
  permissions: string[]
  regions: Region[]
}

export interface AdminPermissionItem {
  id: number
  code: string
  name: string
  category: string
  type: number
}

export interface AdminRole {
  id: number
  code: string
  name: string
  description: string
  status: number
  builtIn: boolean
  permissionIds: number[]
  adminCount: number
}

export interface AdminRolePayload {
  code: string
  name: string
  description: string
  permissionIds: number[]
}

export interface AdminAccount {
  id: number
  account: string
  name: string
  status: number
  roleIds: number[]
  roleNames: string[]
  regions: Region[]
  lastLoginAt: string
}

export interface AdminAccountCreatePayload {
  account: string
  password: string
  name: string
  roleIds: number[]
  regions: Region[]
}

export interface AdminAccountUpdatePayload {
  name: string
  roleIds: number[]
  regions: Region[]
}

export interface AdminMenuItem {
  code: string
  name: string
  path: string
  children: AdminMenuItem[]
}

export interface AdminShopSummary {
  id: number
  merchantId: number
  merchantName: string
  name: string
  region: Region
  categoryName: string
  cityName: string
  areaName: string
  pricePerCapita: number
  status: number
  statusText: string
  openNow: boolean
  createdAt: string
}

export interface AdminShopDetail {
  id: number
  merchantId: number
  merchantName: string
  region: Region
  categoryId: number
  categoryName: string
  cityId: number
  cityName: string
  areaId: number
  areaName: string
  name: string
  coverUrl: string
  phone: string
  score: number
  tasteScore: number
  envScore: number
  serviceScore: number
  pricePerCapita: number
  currency: string
  address: string
  latitude: number | null
  longitude: number | null
  businessHours: string
  summary: string
  hasDeal: boolean
  openNow: boolean
  status: number
  statusText: string
  tags: string[]
  createdAt: string
  updatedAt: string
}

export interface AdminShopSavePayload {
  merchantId: number
  region: Region
  categoryId: number
  cityId: number
  areaId: number
  name: string
  coverUrl: string
  phone: string
  pricePerCapita: number
  currency: string
  address: string
  latitude: number | null
  longitude: number | null
  businessHours: string
  summary: string
  score: number
  tasteScore: number
  envScore: number
  serviceScore: number
  hasDeal: boolean
  openNow: boolean
  status: number
  tags: string[]
}

export interface AdminImportRecord {
  merchantAccount: string
  companyName: string
  contactName: string
  contactPhone: string
  shopName: string
  categoryId: number
  cityId: number
  areaId: number
  address: string
  latitude?: number
  longitude?: number
  phone: string
  businessHours: string
  pricePerCapita: number
  coverUrl: string
  summary: string
  score: number
  tasteScore: number
  envScore: number
  serviceScore: number
  currency?: string
  hasDeal?: boolean
  openNow?: boolean
  tags?: string[]
}

export interface AdminImportPayload {
  fileName: string
  region: Region
  records: AdminImportRecord[]
}

export interface AdminImportResult {
  batchId: number
  total: number
  success: number
  failed: number
  status: number
  statusText: string
  errorFile: string
  errorMessages: string[]
}

export interface AdminImportBatch {
  id: number
  fileName: string
  region: Region
  total: number
  success: number
  failed: number
  status: number
  statusText: string
  errorFile: string
  createdAt: string
}

export interface AdminAuditTask {
  id: number
  bizType: number
  bizTypeText: string
  bizId: number
  region: Region
  status: number
  statusText: string
  shopId: number | null
  shopName: string
  submittedBy: string
  summary: string
  remark: string
  createdAt: string
  updatedAt: string
}

export interface AdminMerchantApplication {
  merchantId: number
  merchantAccount: string
  companyName: string
  region: Region
  licenseUrl: string
  legalPerson: string
  shopPhotoUrls: string[]
  status: number
  statusText: string
  rejectReason: string
  submittedAt: string
  auditedAt: string
}

export interface CategoryChild {
  id: number
  name: string
}

export interface CategoryNode {
  id: number
  name: string
  children: CategoryChild[]
}

export interface City {
  id: number
  name: string
}

export interface Area {
  id: number
  cityId: number
  name: string
}

export interface AdminGeoCategory {
  id: number
  parentId: number
  name: string
  sortNo: number
  status: number
}

export interface AdminGeoCity {
  id: number
  code: string
  name: string
  sortNo: number
  status: number
}

export interface AdminGeoArea {
  id: number
  cityId: number
  name: string
  sortNo: number
  status: number
}

export interface GeoCategoryPayload {
  parentId: number
  name: string
  sortNo: number
}

export interface GeoCityPayload {
  code: string
  name: string
  sortNo: number
}

export interface GeoAreaPayload {
  cityId: number
  name: string
  sortNo: number
}

export interface RankConfig {
  id: number
  rankType: number
  rankTypeText: string
  region: Region
  cityId: number
  categoryId: number
  version: number
  calcCycle: number
  weight: Record<string, number>
  minReviewCount: number
  minScore: number
  manualIntervene: boolean
  status: number
  statusText: string
  effectiveFrom: string
  updatedAt: string
}

export interface RankConfigPayload {
  rankType: number
  region: Region
  cityId: number
  categoryId: number
  calcCycle: number
  weight: Record<string, number>
  minReviewCount: number
  minScore: number
  manualIntervene: boolean
}

export interface RankPublishResult {
  config: RankConfig
  rankId: number
  itemCount: number
}

export interface GrowthRule { id: number; action: string; actionName: string; growthValue: number; points: number; dailyLimit: number; enabled: boolean; updatedAt: string }
export interface LevelConfig { level: number; minGrowth: number; levelName: string; icon: string; privilegeJson: string; enabled: boolean; updatedAt: string }
export interface GrowthConfig { rules: GrowthRule[]; levels: LevelConfig[] }
export interface GrowthRulePayload { action: string; actionName: string; growthValue: number; points: number; dailyLimit: number; enabled: boolean }
