import type { Region } from '@/types/browse'

export type AuthMode = 'password' | 'code' | 'register' | 'reset'

export interface AuthUser {
  id: number
  nickname: string
  avatar: string
  preferredRegion: Region
}

export interface AuthSessionResponse {
  accessToken: string
  refreshToken: string
  user: AuthUser
}

export interface AuthCurrentUser {
  id: number
  nickname: string
  avatar: string
  email: string | null
  phone: string | null
  hasPassword: boolean
  gender: number
  signature: string
  preferredRegion: Region
  level: number
  points: number
  growthValue: number
}

export interface PublicUserProfile {
  id: number
  nickname: string
  avatar: string
  signature: string
  preferredRegion: Region
  level: number
  points: number
  growthValue: number
  reviewCount: number
  followerCount: number
  followingCount: number
  followedByCurrentUser: boolean
}

export interface SocialUserSummary {
  id: number
  nickname: string
  avatar: string
  signature: string
  level: number
  followerCount: number
  followedByCurrentUser: boolean
  followedAt: string
}

export interface UserGrowthRecord {
  id: number
  type: number
  typeText: string
  action: string
  actionText: string
  bizId: number | null
  changeAmount: number
  balanceAfter: number
  remark: string
  createdAt: string
}

export interface AuthSendCodeResponse {
  sent: boolean
  expireSeconds: number
  nextRetrySeconds: number
  mockCode: string
}

export interface UserProfileUpdatePayload {
  nickname: string
  avatar: string
  gender: number
  signature: string
}

export interface UserBindPayload {
  type: 'email' | 'phone'
  account: string
  code: string
}

export interface UserPasswordUpdatePayload {
  oldPassword?: string
  newPassword: string
}
