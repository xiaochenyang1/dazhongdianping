import { reactive } from 'vue'

export type MerchantRegion = 'CN' | 'EU'

interface MerchantSessionPayload {
  accessToken: string
  merchantId: number
  account: string
  region: MerchantRegion
}

export interface MerchantSessionSnapshot {
  revision: number
  token?: string
  region: MerchantRegion
}

const TOKEN_KEY = 'dzdp:merchant-token'
const MERCHANT_ID_KEY = 'dzdp:merchant-id'
const ACCOUNT_KEY = 'dzdp:merchant-account'
const REGION_KEY = 'dzdp:merchant-region'

const state = reactive<{
  token?: string
  merchantId?: number
  account?: string
  region: MerchantRegion
}>( {
  token: localStorage.getItem(TOKEN_KEY) ?? undefined,
  merchantId: Number(localStorage.getItem(MERCHANT_ID_KEY)) || undefined,
  account: localStorage.getItem(ACCOUNT_KEY) ?? undefined,
  region: localStorage.getItem(REGION_KEY) === 'EU' ? 'EU' : 'CN',
} )

let sessionRevision = 0

function setSession(payload: MerchantSessionPayload) {
  sessionRevision += 1
  state.token = payload.accessToken
  state.merchantId = payload.merchantId
  state.account = payload.account
  state.region = payload.region
  localStorage.setItem(TOKEN_KEY, payload.accessToken)
  localStorage.setItem(MERCHANT_ID_KEY, String(payload.merchantId))
  localStorage.setItem(ACCOUNT_KEY, payload.account)
  localStorage.setItem(REGION_KEY, payload.region)
}

function clearSession() {
  sessionRevision += 1
  state.token = undefined
  state.merchantId = undefined
  state.account = undefined
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(MERCHANT_ID_KEY)
  localStorage.removeItem(ACCOUNT_KEY)
}

function snapshotSession(): MerchantSessionSnapshot {
  return {
    revision: sessionRevision,
    token: state.token,
    region: state.region,
  }
}

function matchesSession(snapshot: MerchantSessionSnapshot) {
  return sessionRevision === snapshot.revision
    && state.token === snapshot.token
    && state.region === snapshot.region
}

function clearSessionIfCurrent(snapshot: MerchantSessionSnapshot) {
  if (!matchesSession(snapshot)) return false
  clearSession()
  return true
}

export function useMerchantSession() {
  return {
    state,
    setSession,
    clearSession,
    snapshotSession,
    clearSessionIfCurrent,
  }
}
