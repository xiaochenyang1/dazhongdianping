import { reactive } from 'vue'
import type {
  AuthCurrentUser,
  AuthMode,
  AuthSessionResponse,
  UserExpertCertificationStatus,
} from '@/types/auth'

const ACCESS_TOKEN_STORAGE_KEY = 'dzdp:user-access-token'
const REFRESH_TOKEN_STORAGE_KEY = 'dzdp:user-refresh-token'
const PROFILE_STORAGE_KEY = 'dzdp:user-profile'

type PendingAuthAction = () => void | Promise<void>

export interface UserSessionSnapshot {
  revision: number
  accessToken?: string
  refreshToken?: string
}

function emptyExpertCertificationStatus(): UserExpertCertificationStatus {
  return {
    id: null,
    status: 0,
    statusText: '未申请',
    reason: '',
    rejectReason: '',
    badge: null,
    submittedAt: '',
    reviewedAt: '',
    effectiveStartAt: '',
    effectiveEndAt: '',
  }
}

function parseCurrentUser(rawValue: string | null): AuthCurrentUser | undefined {
  if (!rawValue) {
    return undefined
  }

  try {
    const parsed = JSON.parse(rawValue) as AuthCurrentUser
    if (
      typeof parsed.id === 'number' &&
      typeof parsed.nickname === 'string' &&
      typeof parsed.avatar === 'string' &&
      typeof parsed.preferredRegion === 'string'
    ) {
      return {
        ...parsed,
        email: parsed.email ?? null,
        phone: parsed.phone ?? null,
        hasPassword: typeof parsed.hasPassword === 'boolean' ? parsed.hasPassword : false,
        gender: typeof parsed.gender === 'number' ? parsed.gender : 0,
        signature: typeof parsed.signature === 'string' ? parsed.signature : '',
        level: typeof parsed.level === 'number' ? parsed.level : 1,
        points: typeof parsed.points === 'number' ? parsed.points : 0,
        growthValue: typeof parsed.growthValue === 'number' ? parsed.growthValue : 0,
        expertCertification: parsed.expertCertification ?? emptyExpertCertificationStatus(),
      }
    }
  } catch {
    localStorage.removeItem(PROFILE_STORAGE_KEY)
  }

  return undefined
}

function toCurrentUser(session: AuthSessionResponse): AuthCurrentUser {
  return {
    id: session.user.id,
    nickname: session.user.nickname,
    avatar: session.user.avatar,
    email: null,
    phone: null,
    hasPassword: false,
    gender: 0,
    signature: '',
    preferredRegion: session.user.preferredRegion,
    level: 1,
    points: 0,
    growthValue: 0,
    expertCertification: emptyExpertCertificationStatus(),
  }
}

const state = reactive<{
  accessToken?: string
  refreshToken?: string
  currentUser?: AuthCurrentUser
  authDialogOpen: boolean
  authMode: AuthMode
  redirectTo?: string
  pendingAuthAction?: PendingAuthAction
  initializing: boolean
}>( {
  accessToken: localStorage.getItem(ACCESS_TOKEN_STORAGE_KEY) ?? undefined,
  refreshToken: localStorage.getItem(REFRESH_TOKEN_STORAGE_KEY) ?? undefined,
  currentUser: parseCurrentUser(localStorage.getItem(PROFILE_STORAGE_KEY)),
  authDialogOpen: false,
  authMode: 'password',
  redirectTo: undefined,
  pendingAuthAction: undefined,
  initializing: false,
} )

let sessionRevision = 0

function writeSession(session: AuthSessionResponse, currentUser: AuthCurrentUser) {
  state.accessToken = session.accessToken
  state.refreshToken = session.refreshToken
  state.currentUser = currentUser

  localStorage.setItem(ACCESS_TOKEN_STORAGE_KEY, session.accessToken)
  localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, session.refreshToken)
  localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(currentUser))
}

function setSession(session: AuthSessionResponse) {
  sessionRevision += 1
  writeSession(session, toCurrentUser(session))
}

function snapshotSession(): UserSessionSnapshot {
  return {
    revision: sessionRevision,
    accessToken: state.accessToken,
    refreshToken: state.refreshToken,
  }
}

function matchesSession(snapshot: UserSessionSnapshot) {
  return (
    sessionRevision === snapshot.revision &&
    state.accessToken === snapshot.accessToken &&
    state.refreshToken === snapshot.refreshToken
  )
}

function rotateSessionIfCurrent(snapshot: UserSessionSnapshot, session: AuthSessionResponse) {
  if (!matchesSession(snapshot)) {
    return false
  }

  if (state.currentUser && state.currentUser.id !== session.user.id) {
    return false
  }

  const currentUser = state.currentUser
    ? {
        ...state.currentUser,
        nickname: session.user.nickname,
        avatar: session.user.avatar,
        preferredRegion: session.user.preferredRegion,
      }
    : toCurrentUser(session)
  writeSession(session, currentUser)
  return true
}

function setCurrentUser(currentUser: AuthCurrentUser) {
  state.currentUser = currentUser
  localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(currentUser))
}

function clearSession() {
  sessionRevision += 1
  state.accessToken = undefined
  state.refreshToken = undefined
  state.currentUser = undefined
  localStorage.removeItem(ACCESS_TOKEN_STORAGE_KEY)
  localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY)
  localStorage.removeItem(PROFILE_STORAGE_KEY)
}

function clearSessionIfCurrent(snapshot: UserSessionSnapshot) {
  if (!matchesSession(snapshot)) {
    return false
  }

  clearSession()
  return true
}

function openAuthDialog(options?: { mode?: AuthMode; redirectTo?: string; afterLogin?: PendingAuthAction }) {
  state.authDialogOpen = true
  state.authMode = options?.mode ?? 'password'
  state.redirectTo = options?.redirectTo ?? state.redirectTo
  state.pendingAuthAction = options?.afterLogin ?? state.pendingAuthAction
}

function closeAuthDialog() {
  state.authDialogOpen = false
  state.redirectTo = undefined
  state.pendingAuthAction = undefined
}

function consumePendingAuthAction() {
  const pendingAction = state.pendingAuthAction
  state.pendingAuthAction = undefined
  return pendingAction
}

function setAuthMode(mode: AuthMode) {
  state.authMode = mode
}

function setInitializing(initializing: boolean) {
  state.initializing = initializing
}

export function useUserSession() {
  return {
    state,
    setSession,
    snapshotSession,
    rotateSessionIfCurrent,
    setCurrentUser,
    clearSession,
    clearSessionIfCurrent,
    openAuthDialog,
    closeAuthDialog,
    consumePendingAuthAction,
    setAuthMode,
    setInitializing,
  }
}
