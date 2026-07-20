import axios, { AxiosError, type AxiosRequestConfig } from 'axios'
import { useMerchantSession } from '@/composables/useMerchantSession'

interface ApiEnvelope<T> { code: number; message: string; data: T; traceId?: string }

const http = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL ?? '', timeout: 10000 })

function headers() {
  const { state } = useMerchantSession()
  const result: Record<string, string> = { 'Accept-Language': 'zh-CN', 'X-Region': state.region }
  if (state.token) result.Authorization = `Bearer ${state.token}`
  return result
}

function idempotencyKey() {
  return globalThis.crypto?.randomUUID?.() ?? `merchant-${Date.now()}-${Math.random().toString(16).slice(2)}`
}

async function request<T>(config: AxiosRequestConfig) {
  try {
    const response = await http.request<ApiEnvelope<T>>({
      ...config,
      headers: { ...headers(), ...(config.headers ?? {}) },
    })
    if (response.data.code !== 0) throw new Error(response.data.message || '请求失败')
    return response.data.data
  } catch (error) {
    if (error instanceof Error && !(error instanceof AxiosError)) throw error
    if (axios.isAxiosError(error)) {
      if (error.response?.status === 401) useMerchantSession().clearSession()
      const data = error.response?.data as Partial<ApiEnvelope<unknown>> | undefined
      throw new Error(data?.message || error.message || '请求失败')
    }
    throw new Error('请求失败')
  }
}

export function apiGet<T>(url: string, params?: object) { return request<T>({ url, method: 'GET', params }) }
export function apiPost<T>(url: string, data?: unknown) {
  return request<T>({ url, method: 'POST', data, headers: { 'Idempotency-Key': idempotencyKey() } })
}
export function apiPut<T>(url: string, data?: unknown) {
  return request<T>({ url, method: 'PUT', data, headers: { 'Idempotency-Key': idempotencyKey() } })
}
