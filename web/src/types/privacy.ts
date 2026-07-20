import type { PageResult } from '@/types/browse'

export type PrivacyExportModule =
  | 'account'
  | 'orders'
  | 'reviews'
  | 'posts'
  | 'reservations'
  | 'favorites'
  | 'follows'

export interface PrivacyExportRule {
  dailyLimit: number
  defaultFormat: string
  expireHours: number
}

export interface PrivacyDeleteRule {
  coolingOffDays: number
  reverifyRequired: boolean
}

export interface PrivacyExportTask {
  id: number
  status: number
  statusText: string
  modules: PrivacyExportModule[]
  format: string
  downloadUrl: string
  expireAt: string | null
  failReason: string
  createdAt: string
  updatedAt: string
}

export interface PrivacyDeleteTask {
  id: number
  status: number
  statusText: string
  verifyType: 'code' | 'password'
  account: string
  reason: string
  coolingOffExpireAt: string | null
  completedAt: string | null
  cancelledAt: string | null
  createdAt: string
  updatedAt: string
}

export interface PrivacyOverview {
  exportRule: PrivacyExportRule
  deleteRule: PrivacyDeleteRule
  latestExportTask: PrivacyExportTask | null
  latestDeleteTask: PrivacyDeleteTask | null
}

export interface PrivacyExportTaskCreatePayload {
  modules: PrivacyExportModule[]
  format: 'zip'
}

export interface PrivacyDeleteTaskCreatePayload {
  verifyType: 'code' | 'password'
  account: string
  verifyCode?: string
  password?: string
  reason: string
}

export type PrivacyExportTaskPage = PageResult<PrivacyExportTask>

export interface PrivacyPolicyAcceptLog {
  id: number
  policyType: number
  version: string
  locale: string
  source: number
  requestIp: string
  userAgent: string
  acceptedAt: string
}

export interface PrivacyPolicyAcceptPayload {
  policyType: 1 | 2 | 3
  version: string
  locale: string
  source: 1 | 2 | 3
}

export interface UserDevice {
  id: number
  deviceUid: string
  platform: number
  pushChannel: number
  pushTokenSet: boolean
  appVersion: string
  status: number
  lastActiveAt: string | null
  createdAt: string
  updatedAt: string
}
