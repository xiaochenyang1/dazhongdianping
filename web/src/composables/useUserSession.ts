import { reactive } from 'vue'
import type { AuthCurrentUser, AuthMode, AuthSessionResponse } from '@/types/auth'

const ACCESS_TOKEN_STORAGE_KEY = 'dzdp:user-access-token'
const REFRESH_TOKEN_STORAGE_KEY = 'dzdp:user-refresh-token'
const PROFILE_STORAGE_KEY = 'dzdp:user-profile'

type PendingAuthAction = () => void | Promise<void>

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

function setSession(session: AuthSessionResponse) {
  state.accessToken = session.accessToken
  state.refreshToken = session.refreshToken
  state.currentUser = toCurrentUser(session)

  localStorage.setItem(ACCESS_TOKEN_STORAGE_KEY, session.accessToken)
  localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, session.refreshToken)
  localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(state.currentUser))
}

function setCurrentUser(currentUser: AuthCurrentUser) {
  state.currentUser = currentUser
  localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(currentUser))
}

function clearSession() {
  state.accessToken = undefined
  state.refreshToken = undefined
  state.currentUser = undefined
  localStorage.removeItem(ACCESS_TOKEN_STORAGE_KEY)
  localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY)
  localStorage.removeItem(PROFILE_STORAGE_KEY)
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
    setCurrentUser,
    clearSession,
    openAuthDialog,
    closeAuthDialog,
    consumePendingAuthAction,
    setAuthMode,
    setInitializing,
  }
}
