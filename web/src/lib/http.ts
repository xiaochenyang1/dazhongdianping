import axios, { AxiosError, type AxiosRequestConfig } from 'axios'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession } from '@/composables/useUserSession'
import type { AuthSessionResponse } from '@/types/auth'

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
  const { state: appState } = useAppContext()
  const { state: sessionState } = useUserSession()
  const headers: Record<string, string> = {
    'Accept-Language': 'zh-CN',
    'X-Region': appState.region,
  }

  if (sessionState.accessToken) {
    headers.Authorization = `Bearer ${sessionState.accessToken}`
  }

  return headers
}

function createIdempotencyKey() {
  if (globalThis.crypto?.randomUUID) {
    return globalThis.crypto.randomUUID()
  }

  const randomPart = Math.random().toString(16).slice(2).padEnd(16, '0')
  return `web-${Date.now().toString(16)}-${randomPart}`.slice(0, 64)
}

function idempotencyHeaders() {
  return {
    'Idempotency-Key': createIdempotencyKey(),
  }
}

async function refreshSession() {
  const { state: appState } = useAppContext()
  const { state: sessionState, setSession, clearSession } = useUserSession()

  if (!sessionState.refreshToken) {
    clearSession()
    return false
  }

  try {
    const response = await http.post<ApiEnvelope<AuthSessionResponse>>(
      '/api/c/v1/auth/refresh',
      { refreshToken: sessionState.refreshToken },
      {
        headers: {
          'Accept-Language': 'zh-CN',
          'X-Region': appState.region,
        },
      },
    )

    if (response.data.code !== 0) {
      throw new Error(response.data.message || '刷新登录态失败')
    }

    setSession(response.data.data)
    return true
  } catch {
    clearSession()
    return false
  }
}

interface RetryableRequestConfig extends AxiosRequestConfig {
  _retried?: boolean
}

async function request<T>(config: RetryableRequestConfig) {
  try {
    const response = await http.request<ApiEnvelope<T>>({
      ...config,
      headers: {
        ...buildHeaders(),
        ...(config.headers ?? {}),
      },
    })

    if (response.data.code !== 0) {
      throw new Error(enrichMessage(response.data.message || '请求失败', response.data.traceId))
    }

    return response.data.data
  } catch (error) {
    if (error instanceof Error && !(error instanceof AxiosError)) {
      throw error
    }

    if (axios.isAxiosError(error)) {
      const status = error.response?.status
      const envelope = error.response?.data as Partial<ApiEnvelope<unknown>> | undefined

      if (status === 401 && !config._retried && config.url !== '/api/c/v1/auth/refresh') {
        const refreshed = await refreshSession()
        if (refreshed) {
          return request<T>({ ...config, _retried: true })
        }
      }

      if (status === 401) {
        useUserSession().clearSession()
      }

      const message = typeof envelope?.message === 'string' ? envelope.message : error.message || '请求失败'
      const traceId = typeof envelope?.traceId === 'string' ? envelope.traceId : undefined
      throw new Error(enrichMessage(message, traceId))
    }

    throw new Error('请求失败')
  }
}

async function downloadRequest(config: RetryableRequestConfig): Promise<Blob> {
  try {
    const response = await http.request<Blob>({
      ...config,
      responseType: 'blob',
      headers: {
        ...buildHeaders(),
        ...(config.headers ?? {}),
      },
    })

    return response.data
  } catch (error) {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status

      if (status === 401 && !config._retried) {
        const refreshed = await refreshSession()
        if (refreshed) {
          return downloadRequest({ ...config, _retried: true })
        }
      }

      if (status === 401) {
        useUserSession().clearSession()
      }

      throw new Error(error.message || '文件下载失败')
    }

    throw new Error('文件下载失败')
  }
}

export function apiGet<T>(url: string, params?: object) {
  return request<T>({ url, method: 'GET', params })
}

export function apiPost<T>(url: string, data?: unknown) {
  return request<T>({ url, method: 'POST', data, headers: idempotencyHeaders() })
}

export function apiPut<T>(url: string, data?: unknown) {
  return request<T>({ url, method: 'PUT', data, headers: idempotencyHeaders() })
}

export function apiDelete<T>(url: string, params?: object) {
  return request<T>({ url, method: 'DELETE', params, headers: idempotencyHeaders() })
}

export function apiDownload(url: string) {
  return downloadRequest({ url, method: 'GET' })
}
