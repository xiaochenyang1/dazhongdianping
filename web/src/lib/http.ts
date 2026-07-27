import axios, { AxiosError, type AxiosRequestConfig } from 'axios'
import { useAppContext } from '@/composables/useAppContext'
import { useUserSession, type UserSessionSnapshot } from '@/composables/useUserSession'
import type { AuthSessionResponse } from '@/types/auth'

interface ApiEnvelope<T> {
  code: number
  message: string
  messageKey: string
  data: T
  traceId: string
}

export class ApiError extends Error {
  readonly status?: number
  readonly messageKey?: string
  readonly traceId?: string

  constructor(message: string, options: { status?: number; messageKey?: string; traceId?: string } = {}) {
    super(message)
    this.name = 'ApiError'
    this.status = options.status
    this.messageKey = options.messageKey
    this.traceId = options.traceId
  }
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

function buildHeaders(accessToken?: string) {
  const { state: appState } = useAppContext()
  const headers: Record<string, string> = {
    'Accept-Language': 'zh-CN',
    'X-Region': appState.region,
  }

  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`
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

interface RefreshFlight {
  revision: number
  refreshToken: string
  promise: Promise<boolean>
}

let refreshFlight: RefreshFlight | undefined

function isSameSnapshot(left: UserSessionSnapshot, right: UserSessionSnapshot) {
  return (
    left.revision === right.revision &&
    left.accessToken === right.accessToken &&
    left.refreshToken === right.refreshToken
  )
}

function refreshSession(snapshot: UserSessionSnapshot) {
  const { state: appState } = useAppContext()
  const session = useUserSession()

  if (!isSameSnapshot(session.snapshotSession(), snapshot)) {
    return Promise.resolve(false)
  }

  if (!snapshot.refreshToken) {
    session.clearSessionIfCurrent(snapshot)
    return Promise.resolve(false)
  }

  if (
    refreshFlight &&
    refreshFlight.revision === snapshot.revision &&
    refreshFlight.refreshToken === snapshot.refreshToken
  ) {
    return refreshFlight.promise
  }

  const region = appState.region
  let promise: Promise<boolean>
  promise = (async () => {
    try {
      const response = await http.post<ApiEnvelope<AuthSessionResponse>>(
        '/api/c/v1/auth/refresh',
        { refreshToken: snapshot.refreshToken },
        {
          headers: {
            'Accept-Language': 'zh-CN',
            'X-Region': region,
          },
        },
      )

      if (response.data.code !== 0) {
        throw new Error(response.data.message || '刷新登录态失败')
      }

      return session.rotateSessionIfCurrent(snapshot, response.data.data)
    } catch {
      session.clearSessionIfCurrent(snapshot)
      return false
    }
  })().finally(() => {
    if (refreshFlight?.promise === promise) {
      refreshFlight = undefined
    }
  })

  refreshFlight = {
    revision: snapshot.revision,
    refreshToken: snapshot.refreshToken,
    promise,
  }
  return promise
}

async function recoverUnauthorized(snapshot: UserSessionSnapshot) {
  const session = useUserSession()
  const current = session.snapshotSession()

  if (current.revision !== snapshot.revision) {
    return false
  }

  if (current.accessToken !== snapshot.accessToken) {
    return Boolean(current.accessToken)
  }

  if (current.refreshToken !== snapshot.refreshToken) {
    return false
  }

  const refreshed = await refreshSession(snapshot)
  const afterRefresh = session.snapshotSession()
  return (
    refreshed &&
    afterRefresh.revision === snapshot.revision &&
    Boolean(afterRefresh.accessToken) &&
    afterRefresh.accessToken !== snapshot.accessToken
  )
}

interface RetryableRequestConfig extends AxiosRequestConfig {
  _retried?: boolean
}

async function request<T>(config: RetryableRequestConfig) {
  const session = useUserSession()
  const sentSession = session.snapshotSession()

  try {
    const response = await http.request<ApiEnvelope<T>>({
      ...config,
      headers: {
        ...buildHeaders(sentSession.accessToken),
        ...(config.headers ?? {}),
      },
    })

    if (response.data.code !== 0) {
      throw new ApiError(enrichMessage(response.data.message || '请求失败', response.data.traceId), {
        messageKey: response.data.messageKey,
        traceId: response.data.traceId,
      })
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
        const refreshed = await recoverUnauthorized(sentSession)
        if (refreshed) {
          return request<T>({ ...config, _retried: true })
        }
      }

      if (status === 401) {
        session.clearSessionIfCurrent(sentSession)
      }

      const message = typeof envelope?.message === 'string' ? envelope.message : error.message || '请求失败'
      const traceId = typeof envelope?.traceId === 'string' ? envelope.traceId : undefined
      const messageKey = typeof envelope?.messageKey === 'string' ? envelope.messageKey : undefined
      throw new ApiError(enrichMessage(message, traceId), { status, messageKey, traceId })
    }

    throw new ApiError('请求失败')
  }
}

async function downloadRequest(config: RetryableRequestConfig): Promise<Blob> {
  const session = useUserSession()
  const sentSession = session.snapshotSession()

  try {
    const response = await http.request<Blob>({
      ...config,
      responseType: 'blob',
      headers: {
        ...buildHeaders(sentSession.accessToken),
        ...(config.headers ?? {}),
      },
    })

    return response.data
  } catch (error) {
    if (axios.isAxiosError(error)) {
      const status = error.response?.status

      if (status === 401 && !config._retried) {
        const refreshed = await recoverUnauthorized(sentSession)
        if (refreshed) {
          return downloadRequest({ ...config, _retried: true })
        }
      }

      if (status === 401) {
        session.clearSessionIfCurrent(sentSession)
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
