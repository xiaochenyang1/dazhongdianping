import axios, { AxiosError, type AxiosRequestConfig } from 'axios'
import { useAdminSession } from '@/composables/useAdminSession'
import { adminStringsForRegion, localeForRegion } from '@/core/admin_localizations'

interface ApiEnvelope<T> {
  code: number
  message: string
  messageKey: string
  data: T
  traceId: string
}

const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? '',
  timeout: 10000,
})

function enrichMessage(message: string, traceId?: string) {
  if (!traceId) {
    return message
  }
  return `${message} [traceId: ${traceId}]`
}

function buildHeaders() {
  const { state } = useAdminSession()
  const headers: Record<string, string> = {
    'Accept-Language': localeForRegion(state.region),
    'X-Region': state.region,
  }

  if (state.token) {
    headers.Authorization = `Bearer ${state.token}`
  }

  return headers
}

async function request<T>(config: AxiosRequestConfig) {
  const { state } = useAdminSession()
  const strings = adminStringsForRegion(state.region)
  try {
    const response = await http.request<ApiEnvelope<T>>({
      ...config,
      headers: {
        ...buildHeaders(),
        ...(config.headers ?? {}),
      },
    })

    if (response.data.code !== 0) {
      throw new Error(enrichMessage(response.data.message || strings.common.requestFailed, response.data.traceId))
    }

    return response.data.data
  } catch (error) {
    if (error instanceof Error && !(error instanceof AxiosError)) {
      throw error
    }

    if (axios.isAxiosError(error)) {
      const { clearSession } = useAdminSession()
      const status = error.response?.status
      const envelope = error.response?.data as Partial<ApiEnvelope<unknown>> | undefined

      if (status === 401) {
        clearSession()
      }

      const message = typeof envelope?.message === 'string' ? envelope.message : error.message || strings.common.requestFailed
      const traceId = typeof envelope?.traceId === 'string' ? envelope.traceId : undefined
      throw new Error(enrichMessage(message, traceId))
    }

    throw new Error(strings.common.requestFailed)
  }
}

export function apiGet<T>(url: string, params?: object) {
  return request<T>({ url, method: 'GET', params })
}

export function apiPost<T>(url: string, data?: object) {
  return request<T>({ url, method: 'POST', data })
}

export function apiPut<T>(url: string, data?: object) {
  return request<T>({ url, method: 'PUT', data })
}

export function apiDelete<T>(url: string) {
  return request<T>({ url, method: 'DELETE' })
}
