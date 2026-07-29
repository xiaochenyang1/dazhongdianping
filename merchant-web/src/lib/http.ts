import axios, { AxiosError, type AxiosRequestConfig } from 'axios'
import {
  useMerchantSession,
  type MerchantSessionSnapshot,
} from '@/composables/useMerchantSession'
import {
  localeForRegion,
  merchantStringsForRegion,
} from '@/core/merchant_localizations'

interface ApiEnvelope<T> { code: number; message: string; data: T; traceId?: string }

const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL ?? '', timeout: 10000 })

function headers(snapshot: MerchantSessionSnapshot) {
  const result: Record<string, string> = {
    'Accept-Language': localeForRegion(snapshot.region),
    'X-Region': snapshot.region,
  }
  if (snapshot.token) result.Authorization = `Bearer ${snapshot.token}`
  return result
}

function idempotencyKey() {
  return globalThis.crypto?.randomUUID?.() ?? `merchant-${Date.now()}-${Math.random().toString(16).slice(2)}`
}

async function request<T>(config: AxiosRequestConfig) {
  const session = useMerchantSession()
  const snapshot = session.snapshotSession()
  const strings = merchantStringsForRegion(snapshot.region)
  try {
    const response = await http.request<ApiEnvelope<T>>({
      ...config,
      headers: { ...headers(snapshot), ...(config.headers ?? {}) },
    })
    if (response.data.code !== 0) throw new Error(response.data.message || strings.common.requestFailed)
    return response.data.data
  } catch (error) {
    if (error instanceof Error && !(error instanceof AxiosError)) throw error
    if (axios.isAxiosError(error)) {
      if (error.response?.status === 401) session.clearSessionIfCurrent(snapshot)
      const data = error.response?.data as Partial<ApiEnvelope<unknown>> | undefined
      throw new Error(data?.message || error.message || strings.common.requestFailed)
    }
    throw new Error(strings.common.requestFailed)
  }
}

export function apiGet<T>(url: string, params?: object) { return request<T>({ url, method: 'GET', params }) }
export function apiPost<T>(url: string, data?: unknown) {
  return request<T>({ url, method: 'POST', data, headers: { 'Idempotency-Key': idempotencyKey() } })
}
export function apiPut<T>(url: string, data?: unknown) {
  return request<T>({ url, method: 'PUT', data, headers: { 'Idempotency-Key': idempotencyKey() } })
}
