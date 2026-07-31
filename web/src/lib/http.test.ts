import type { AxiosRequestConfig } from 'axios'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { AuthCurrentUser, AuthSessionResponse } from '@/types/auth'

const axiosMock = vi.hoisted(() => ({
  request: vi.fn(),
  post: vi.fn(),
}))

vi.mock('axios', async (importOriginal) => {
  const actual = await importOriginal<typeof import('axios')>()
  return {
    ...actual,
    default: {
      create: () => axiosMock,
      isAxiosError: actual.default.isAxiosError,
    },
  }
})

const oldSession: AuthSessionResponse = {
  accessToken: 'old-access',
  refreshToken: 'old-refresh',
  user: {
    id: 7,
    nickname: 'Old nickname',
    avatar: '/old-avatar.png',
    preferredRegion: 'CN',
  },
}

const rotatedSession: AuthSessionResponse = {
  accessToken: 'new-access',
  refreshToken: 'new-refresh',
  user: {
    id: 7,
    nickname: 'Updated nickname',
    avatar: '/new-avatar.png',
    preferredRegion: 'EU',
  },
}

const replacementSession: AuthSessionResponse = {
  accessToken: 'replacement-access',
  refreshToken: 'replacement-refresh',
  user: {
    id: 11,
    nickname: 'Replacement user',
    avatar: '/replacement-avatar.png',
    preferredRegion: 'EU',
  },
}

const enrichedProfile: AuthCurrentUser = {
  id: 7,
  nickname: 'Loaded nickname',
  avatar: '/loaded-avatar.png',
  email: 'user@example.com',
  phone: '13800000000',
  hasPassword: true,
  gender: 1,
  signature: 'A loaded profile',
  preferredRegion: 'CN',
  level: 8,
  points: 120,
  growthValue: 450,
  expertCertification: {
    id: 3,
    status: 2,
    statusText: 'Certified',
    reason: 'Local expert',
    rejectReason: '',
    badge: { code: 'expert', label: 'Expert' },
    submittedAt: '2026-01-01T00:00:00',
    reviewedAt: '2026-01-02T00:00:00',
    effectiveStartAt: '2026-01-02T00:00:00',
    effectiveEndAt: '2027-01-02T00:00:00',
  },
}

function deferred<T>() {
  let resolve!: (value: T | PromiseLike<T>) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((resolvePromise, rejectPromise) => {
    resolve = resolvePromise
    reject = rejectPromise
  })
  return { promise, resolve, reject }
}

function successEnvelope<T>(data: T) {
  return {
    data: {
      code: 0,
      message: '',
      messageKey: '',
      data,
      traceId: 'trace-success',
    },
  }
}

function unauthorizedError() {
  return {
    isAxiosError: true,
    message: 'Request failed with status code 401',
    response: {
      status: 401,
      data: {
        code: 401,
        message: 'Session expired',
        messageKey: 'auth.unauthorized',
        traceId: 'trace-401',
      },
    },
  }
}

function accessToken(config: AxiosRequestConfig) {
  return (config.headers as Record<string, string> | undefined)?.Authorization
}

async function loadModules() {
  const sessionModule = await import('@/composables/useUserSession')
  const httpModule = await import('./http')
  return {
    session: sessionModule.useUserSession(),
    http: httpModule,
  }
}

describe('HTTP session refresh', () => {
  beforeEach(() => {
    localStorage.clear()
    axiosMock.request.mockReset()
    axiosMock.post.mockReset()
    vi.resetModules()
  })

  it('shares one refresh between API and download requests and preserves the loaded profile', async () => {
    localStorage.setItem('dzdp:region', 'EU')
    const refresh = deferred<ReturnType<typeof successEnvelope<AuthSessionResponse>>>()
    axiosMock.post.mockReturnValue(refresh.promise)
    axiosMock.request.mockImplementation((config: AxiosRequestConfig) => {
      if (accessToken(config) === 'Bearer old-access') {
        return Promise.reject(unauthorizedError())
      }
      if (config.responseType === 'blob') {
        return Promise.resolve({ data: new Blob(['report']) })
      }
      return Promise.resolve(successEnvelope({ source: 'api' }))
    })

    const { session, http } = await loadModules()
    session.setSession(oldSession)
    session.setCurrentUser(enrichedProfile)

    const apiResult = http.apiGet<{ source: string }>('/api/c/v1/example')
    const downloadResult = http.apiDownload('/api/c/v1/report')

    await vi.waitFor(() => expect(axiosMock.post).toHaveBeenCalledTimes(1))
    expect(axiosMock.post).toHaveBeenCalledWith(
      '/api/c/v1/auth/refresh',
      { refreshToken: 'old-refresh' },
      {
        headers: {
          'Accept-Language': 'en',
          'X-Region': 'EU',
        },
      },
    )

    refresh.resolve(successEnvelope(rotatedSession))

    await expect(apiResult).resolves.toEqual({ source: 'api' })
    await expect(downloadResult).resolves.toBeInstanceOf(Blob)
    expect(axiosMock.request).toHaveBeenCalledTimes(4)

    const retriedConfigs = axiosMock.request.mock.calls
      .map(([config]) => config as AxiosRequestConfig)
      .filter((config) => accessToken(config) === 'Bearer new-access')
    expect(retriedConfigs).toHaveLength(2)
    expect(session.state.accessToken).toBe('new-access')
    expect(session.state.refreshToken).toBe('new-refresh')
    expect(localStorage.getItem('dzdp:user-access-token')).toBe('new-access')
    expect(localStorage.getItem('dzdp:user-refresh-token')).toBe('new-refresh')
    expect(session.state.currentUser).toMatchObject({
      id: 7,
      nickname: 'Updated nickname',
      avatar: '/new-avatar.png',
      preferredRegion: 'EU',
      email: 'user@example.com',
      level: 8,
      points: 120,
      expertCertification: enrichedProfile.expertCertification,
    })
    expect(JSON.parse(localStorage.getItem('dzdp:user-profile') ?? '{}')).toMatchObject({
      nickname: 'Updated nickname',
      email: 'user@example.com',
      level: 8,
    })
  })

  it('retries a late 401 with the rotated token without refreshing again', async () => {
    const refresh = deferred<ReturnType<typeof successEnvelope<AuthSessionResponse>>>()
    const lateRequest = deferred<never>()
    axiosMock.post.mockReturnValue(refresh.promise)
    axiosMock.request.mockImplementation((config: AxiosRequestConfig) => {
      if (config.url === '/api/c/v1/late' && accessToken(config) === 'Bearer old-access') {
        return lateRequest.promise
      }
      if (accessToken(config) === 'Bearer old-access') {
        return Promise.reject(unauthorizedError())
      }
      return Promise.resolve(successEnvelope(config.url))
    })

    const { session, http } = await loadModules()
    session.setSession(oldSession)

    const firstResult = http.apiGet<string>('/api/c/v1/first')
    const lateResult = http.apiGet<string>('/api/c/v1/late')
    await vi.waitFor(() => expect(axiosMock.post).toHaveBeenCalledTimes(1))

    refresh.resolve(successEnvelope(rotatedSession))
    await expect(firstResult).resolves.toBe('/api/c/v1/first')

    lateRequest.reject(unauthorizedError())
    await expect(lateResult).resolves.toBe('/api/c/v1/late')
    expect(axiosMock.post).toHaveBeenCalledTimes(1)

    const lateConfigs = axiosMock.request.mock.calls
      .map(([config]) => config as AxiosRequestConfig)
      .filter((config) => config.url === '/api/c/v1/late')
    expect(lateConfigs.map(accessToken)).toEqual(['Bearer old-access', 'Bearer new-access'])
  })

  it('does not replay or clear a late 401 after the user logs in again', async () => {
    const lateRequest = deferred<never>()
    axiosMock.request.mockReturnValue(lateRequest.promise)

    const { session, http } = await loadModules()
    session.setSession(oldSession)

    const oldRequest = http.apiGet('/api/c/v1/late-session')
    session.setSession(replacementSession)
    lateRequest.reject(unauthorizedError())

    await expect(oldRequest).rejects.toMatchObject({ name: 'ApiError', status: 401 })
    expect(axiosMock.post).not.toHaveBeenCalled()
    expect(axiosMock.request).toHaveBeenCalledTimes(1)
    expect(session.state.currentUser?.id).toBe(11)
    expect(session.state.accessToken).toBe('replacement-access')
    expect(session.state.refreshToken).toBe('replacement-refresh')
    expect(localStorage.getItem('dzdp:user-access-token')).toBe('replacement-access')
    expect(localStorage.getItem('dzdp:user-refresh-token')).toBe('replacement-refresh')
  })

  it.each(['success', 'failure'] as const)(
    'does not mutate a replacement login when an old refresh settles with %s',
    async (outcome) => {
      const refresh = deferred<ReturnType<typeof successEnvelope<AuthSessionResponse>>>()
      axiosMock.post.mockReturnValue(refresh.promise)
      axiosMock.request.mockRejectedValue(unauthorizedError())

      const { session, http } = await loadModules()
      session.setSession(oldSession)

      const oldRequest = http.apiGet('/api/c/v1/protected')
      await vi.waitFor(() => expect(axiosMock.post).toHaveBeenCalledTimes(1))
      session.setSession(replacementSession)

      if (outcome === 'success') {
        refresh.resolve(successEnvelope(rotatedSession))
      } else {
        refresh.reject(new Error('Refresh failed'))
      }

      await expect(oldRequest).rejects.toMatchObject({ name: 'ApiError', status: 401 })
      expect(axiosMock.request).toHaveBeenCalledTimes(1)
      expect(session.state.currentUser?.id).toBe(11)
      expect(session.state.accessToken).toBe('replacement-access')
      expect(session.state.refreshToken).toBe('replacement-refresh')
      expect(localStorage.getItem('dzdp:user-access-token')).toBe('replacement-access')
      expect(localStorage.getItem('dzdp:user-refresh-token')).toBe('replacement-refresh')
    },
  )

  it('does not restore a session after logout while refresh is pending', async () => {
    const refresh = deferred<ReturnType<typeof successEnvelope<AuthSessionResponse>>>()
    axiosMock.post.mockReturnValue(refresh.promise)
    axiosMock.request.mockRejectedValue(unauthorizedError())

    const { session, http } = await loadModules()
    session.setSession(oldSession)

    const oldRequest = http.apiGet('/api/c/v1/protected')
    await vi.waitFor(() => expect(axiosMock.post).toHaveBeenCalledTimes(1))
    session.clearSession()
    refresh.resolve(successEnvelope(rotatedSession))

    await expect(oldRequest).rejects.toMatchObject({ name: 'ApiError', status: 401 })
    expect(axiosMock.request).toHaveBeenCalledTimes(1)
    expect(session.state.accessToken).toBeUndefined()
    expect(session.state.refreshToken).toBeUndefined()
    expect(session.state.currentUser).toBeUndefined()
    expect(localStorage.getItem('dzdp:user-access-token')).toBeNull()
    expect(localStorage.getItem('dzdp:user-refresh-token')).toBeNull()
    expect(localStorage.getItem('dzdp:user-profile')).toBeNull()
  })

  it('clears a failed session once for all refresh waiters', async () => {
    const refresh = deferred<never>()
    axiosMock.post.mockReturnValue(refresh.promise)
    axiosMock.request.mockRejectedValue(unauthorizedError())

    const { session, http } = await loadModules()
    session.setSession(oldSession)
    const removeItem = vi.spyOn(Storage.prototype, 'removeItem')

    const requests = [
      http.apiGet('/api/c/v1/one'),
      http.apiGet('/api/c/v1/two'),
    ]
    await vi.waitFor(() => expect(axiosMock.post).toHaveBeenCalledTimes(1))
    refresh.reject(new Error('Refresh failed'))

    const results = await Promise.allSettled(requests)
    expect(results.every((result) => result.status === 'rejected')).toBe(true)
    expect(axiosMock.request).toHaveBeenCalledTimes(2)
    expect(session.state.accessToken).toBeUndefined()
    expect(session.state.refreshToken).toBeUndefined()
    expect(session.state.currentUser).toBeUndefined()
    expect(localStorage.getItem('dzdp:user-access-token')).toBeNull()
    expect(localStorage.getItem('dzdp:user-refresh-token')).toBeNull()
    expect(localStorage.getItem('dzdp:user-profile')).toBeNull()

    for (const key of ['dzdp:user-access-token', 'dzdp:user-refresh-token', 'dzdp:user-profile']) {
      expect(removeItem.mock.calls.filter(([removedKey]) => removedKey === key)).toHaveLength(1)
    }
    removeItem.mockRestore()
  })

  it('keeps the original idempotency key when retrying a POST', async () => {
    axiosMock.post.mockResolvedValue(successEnvelope(rotatedSession))
    axiosMock.request.mockImplementation((config: AxiosRequestConfig) => {
      if (accessToken(config) === 'Bearer old-access') {
        return Promise.reject(unauthorizedError())
      }
      return Promise.resolve(successEnvelope({ created: true }))
    })

    const { session, http } = await loadModules()
    session.setSession(oldSession)

    await expect(http.apiPost('/api/c/v1/orders', { shopId: 3 })).resolves.toEqual({ created: true })
    expect(axiosMock.request).toHaveBeenCalledTimes(2)
    const [initialConfig, retryConfig] = axiosMock.request.mock.calls.map(
      ([config]) => config as AxiosRequestConfig,
    )
    const initialKey = (initialConfig.headers as Record<string, string>)['Idempotency-Key']
    expect(initialKey).toBeTruthy()
    expect((retryConfig.headers as Record<string, string>)['Idempotency-Key']).toBe(initialKey)
    expect(initialConfig.data).toEqual({ shopId: 3 })
    expect(retryConfig.data).toEqual({ shopId: 3 })
  })

  it('clears the rotated session when its retried request is still unauthorized', async () => {
    axiosMock.post.mockResolvedValue(successEnvelope(rotatedSession))
    axiosMock.request.mockRejectedValue(unauthorizedError())

    const { session, http } = await loadModules()
    session.setSession(oldSession)

    await expect(http.apiGet('/api/c/v1/protected')).rejects.toMatchObject({
      name: 'ApiError',
      status: 401,
    })

    expect(axiosMock.post).toHaveBeenCalledTimes(1)
    expect(axiosMock.request).toHaveBeenCalledTimes(2)
    const sentTokens = axiosMock.request.mock.calls.map(([config]) =>
      accessToken(config as AxiosRequestConfig),
    )
    expect(sentTokens).toEqual(['Bearer old-access', 'Bearer new-access'])
    expect(session.state.accessToken).toBeUndefined()
    expect(session.state.refreshToken).toBeUndefined()
    expect(session.state.currentUser).toBeUndefined()
  })
})
