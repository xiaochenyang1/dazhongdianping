import { reactive } from 'vue'

export type MerchantRegion = 'CN' | 'EU'

interface MerchantSessionPayload {
  accessToken: string
  merchantId: number
  account: string
  region?: MerchantRegion
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

function setSession(payload: MerchantSessionPayload) {
  state.token = payload.accessToken
  state.merchantId = payload.merchantId
  state.account = payload.account
  localStorage.setItem(TOKEN_KEY, payload.accessToken)
  localStorage.setItem(MERCHANT_ID_KEY, String(payload.merchantId))
  localStorage.setItem(ACCOUNT_KEY, payload.account)
  if (payload.region) setRegion(payload.region)
}

function clearSession() {
  state.token = undefined
  state.merchantId = undefined
  state.account = undefined
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(MERCHANT_ID_KEY)
  localStorage.removeItem(ACCOUNT_KEY)
}

function setRegion(region: MerchantRegion) {
  state.region = region
  localStorage.setItem(REGION_KEY, region)
}

export function useMerchantSession() {
  return { state, setSession, clearSession, setRegion }
}
