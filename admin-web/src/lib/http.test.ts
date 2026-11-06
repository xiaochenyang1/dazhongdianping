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

async function loadModules() {
  const sessionModule = await import('@/composables/useAdminSession')
  const httpModule = await import('./http')
  return {
    session: sessionModule.useAdminSession(),
    http: httpModule,
  }
}

describe('admin HTTP localization', () => {
  beforeEach(() => {
    localStorage.clear()
    axiosMock.request.mockReset()
    vi.resetModules()
  })

  it('sends the region locale and clears the admin session on 401', async () => {
    axiosMock.request.mockRejectedValue(unauthorizedError())
    const { session, http } = await loadModules()
    session.setSession(
      'admin-token',
      { id: 7, account: 'eu.admin', name: 'EU Admin' },
      ['system:admin:read'],
      ['EU'],
    )

    await expect(http.apiGet('/api/admin/v1/auth/me')).rejects.toThrow('Session expired')

    const config = axiosMock.request.mock.calls[0][0] as AxiosRequestConfig
    expect(config.headers).toMatchObject({
      Authorization: 'Bearer admin-token',
      'Accept-Language': 'en',
      'X-Region': 'EU',
    })
    expect(session.state.token).toBeUndefined()
    expect(localStorage.getItem('dzdp:admin-token')).toBeNull()
  })

  it('uses the Chinese fallback request message for the CN region', async () => {
    axiosMock.request.mockRejectedValue({})
    const { session, http } = await loadModules()
    session.clearSession()
    session.setRegion('CN')

    await expect(http.apiGet('/api/admin/v1/menus')).rejects.toThrow('请求失败')

    const config = axiosMock.request.mock.calls[0][0] as AxiosRequestConfig
    expect(config.headers).toMatchObject({
      'Accept-Language': 'zh-CN',
      'X-Region': 'CN',
    })
  })
  it('downloads invoice bytes with authentication and region headers', async () => {
    const blob = new Blob(['%PDF-test'], { type: 'application/pdf' })
    axiosMock.request.mockResolvedValue({ data: blob })
    const { session, http } = await loadModules()
    session.setSession('finance-token', { id: 7, account: 'finance', name: 'Finance' }, ['finance:invoice:read'], ['EU'])
    await expect(http.apiDownload('/api/admin/v1/invoices/7/document')).resolves.toBe(blob)
    expect(axiosMock.request.mock.calls[0][0]).toMatchObject({
      responseType: 'blob', headers: { Authorization: 'Bearer finance-token', 'X-Region': 'EU' },
    })
  })

  it('a late unauthorized response cannot clear a newer administrator session', async () => {
    const { session, http } = await loadModules()
    for (const binary of [false, true]) {
      session.setSession('old-token', { id: 7, account: 'old', name: 'Old' }, [], ['CN'])
      let reject!: (error: object) => void
      axiosMock.request.mockReturnValueOnce(new Promise((_, fail) => { reject = fail }))
      const pending = binary ? http.apiDownload('/api/admin/v1/invoices/7/document') : http.apiGet('/api/admin/v1/auth/me')
      session.setSession('new-token', { id: 8, account: 'new', name: 'New' }, [], ['EU'])
      const failed = expect(pending).rejects.toThrow()
      reject(unauthorizedError())
      await failed
      expect(session.state.token).toBe('new-token')
    }
  })

})
