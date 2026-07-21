import { apiGet, apiPost, apiPut } from '@/lib/http'
import type { PageResult } from '@/types/browse'
import type {
  AuthCurrentUser,
  AuthSendCodeResponse,
  AuthSessionResponse,
  PublicUserProfile,
  SocialUserSummary,
  UserGrowthRecord,
  UserBindPayload,
  UserExpertCertificationApplyPayload,
  UserExpertCertificationStatus,
  UserPasswordUpdatePayload,
  UserProfileUpdatePayload,
} from '@/types/auth'

export function sendAuthCode(payload: {
  scene: 'login' | 'register' | 'reset' | 'bind' | 'delete'
  type: 'email' | 'phone'
  account: string
  deviceId: string
}) {
  return apiPost<AuthSendCodeResponse>('/api/c/v1/auth/send-code', payload)
}

export function registerUser(payload: {
  type: 'email' | 'phone'
  account: string
  code: string
  password: string
  nickname?: string
  preferredRegion: string
}) {
  return apiPost<AuthSessionResponse>('/api/c/v1/auth/register', payload)
}

export function loginWithPassword(payload: { account: string; password: string }) {
  return apiPost<AuthSessionResponse>('/api/c/v1/auth/login/password', payload)
}

export function loginWithCode(payload: {
  type: 'email' | 'phone'
  account: string
  code: string
  preferredRegion: string
}) {
  return apiPost<AuthSessionResponse>('/api/c/v1/auth/login/code', payload)
}

export function logoutUser() {
  return apiPost<void>('/api/c/v1/auth/logout')
}

export function fetchCurrentUser() {
  return apiGet<AuthCurrentUser>('/api/c/v1/user/me')
}

export function fetchCurrentUserExpertCertification() {
  return apiGet<UserExpertCertificationStatus>('/api/c/v1/user/expert-certification')
}

export function fetchUserGrowthRecords(query?: { page?: number; pageSize?: number }) {
  return apiGet<PageResult<UserGrowthRecord>>('/api/c/v1/user/growth/records', query)
}

export function applyCurrentUserExpertCertification(payload: UserExpertCertificationApplyPayload) {
  return apiPost<UserExpertCertificationStatus>('/api/c/v1/user/expert-certification/apply', payload)
}

export function updateCurrentUserProfile(payload: UserProfileUpdatePayload) {
  return apiPut<AuthCurrentUser>('/api/c/v1/user/profile', payload)
}

export function bindCurrentUserAccount(payload: UserBindPayload) {
  return apiPost<AuthCurrentUser>('/api/c/v1/user/bind', payload)
}

export function updateCurrentUserPassword(payload: UserPasswordUpdatePayload) {
  return apiPut<void>('/api/c/v1/user/password', payload)
}

export function fetchPublicUserProfile(userId: number) {
  return apiGet<PublicUserProfile>(`/api/c/v1/user/${userId}`)
}

export function fetchUserFollowers(userId: number, query?: { page?: number; pageSize?: number }) {
  return apiGet<PageResult<SocialUserSummary>>(`/api/c/v1/user/${userId}/followers`, query)
}

export function fetchUserFollowing(userId: number, query?: { page?: number; pageSize?: number }) {
  return apiGet<PageResult<SocialUserSummary>>(`/api/c/v1/user/${userId}/following`, query)
}

export function resetPassword(payload: {
  type: 'email' | 'phone'
  account: string
  code: string
  newPassword: string
}) {
  return apiPost<void>('/api/c/v1/auth/password/reset', payload)
}
