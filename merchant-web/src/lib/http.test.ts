import type { AxiosRequestConfig } from 'axios'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const axiosMock = vi.hoisted(() => ({
  request: vi.fn(),
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

function deferred<T>() {
  let resolve!: (value: T | PromiseLike<T>) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((resolvePromise, rejectPromise) => {
    resolve = resolvePromise
    reject = rejectPromise
  })
  return { promise, resolve, reject }
}

function unauthorizedError() {
  return {
    isAxiosError: true,
    message: 'Request failed with status code 401',
    response: {
      status: 401,
      data: { code: 401, message: 'Session expired' },
    },
  }
}

function forbiddenError() {
  return {
    isAxiosError: true,
    message: 'Request failed with status code 403',
    response: {
      status: 403,
      data: { code: 403, message: 'Wrong region' },
    },
  }
}

async function loadModules() {
  const sessionModule = await import('@/composables/useMerchantSession')
  const httpModule = await import('./http')
  return {
    session: sessionModule.useMerchantSession(),
    http: httpModule,
  }
}

describe('merchant HTTP session handling', () => {
  beforeEach(() => {
    localStorage.clear()
    axiosMock.request.mockReset()
    vi.resetModules()
  })

  it('sends the fixed session region and clears the current session on 401', async () => {
    axiosMock.request.mockRejectedValue(unauthorizedError())
    const { session, http } = await loadModules()
    session.setSession({
      accessToken: 'merchant-token',
      merchantId: 7,
      account: 'owner@example.com',
      region: 'EU',
    })

    await expect(http.apiGet('/api/b/v1/account/me')).rejects.toThrow('Session expired')

    const config = axiosMock.request.mock.calls[0][0] as AxiosRequestConfig
    expect(config.headers).toMatchObject({
      Authorization: 'Bearer merchant-token',
      'X-Region': 'EU',
    })
    expect(session.state.token).toBeUndefined()
    expect(localStorage.getItem('dzdp:merchant-token')).toBeNull()
  })

  it('does not let a late 401 clear a replacement login', async () => {
    const request = deferred<never>()
    axiosMock.request.mockReturnValue(request.promise)
    const { session, http } = await loadModules()
    session.setSession({
      accessToken: 'old-token',
      merchantId: 7,
      account: 'old@example.com',
      region: 'EU',
    })

    const oldRequest = http.apiGet('/api/b/v1/dashboard')
    session.setSession({
      accessToken: 'replacement-token',
      merchantId: 8,
      account: 'replacement@example.com',
      region: 'CN',
    })
    request.reject(unauthorizedError())

    await expect(oldRequest).rejects.toThrow('Session expired')
    expect(session.state.token).toBe('replacement-token')
    expect(session.state.merchantId).toBe(8)
    expect(session.state.region).toBe('CN')
    expect(localStorage.getItem('dzdp:merchant-token')).toBe('replacement-token')
  })

  it('keeps an authenticated session when the server rejects only its request region', async () => {
    axiosMock.request.mockRejectedValue(forbiddenError())
    const { session, http } = await loadModules()
    session.setSession({
      accessToken: 'merchant-token',
      merchantId: 7,
      account: 'owner@example.com',
      region: 'EU',
    })

    await expect(http.apiGet('/api/b/v1/dashboard')).rejects.toThrow('Wrong region')

    expect(session.state.token).toBe('merchant-token')
    expect(localStorage.getItem('dzdp:merchant-token')).toBe('merchant-token')
  })
})
