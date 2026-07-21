import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import router from './index'
import { useAdminSession } from '@/composables/useAdminSession'

describe('admin router permissions', () => {
  const scrollTo = vi.fn()

  beforeEach(async () => {
    scrollTo.mockReset()
    vi.stubGlobal('scrollTo', scrollTo)

    const { clearSession, setSession } = useAdminSession() as unknown as {
      clearSession: () => void
      setSession: (token: string, profile: { id: number; account: string; name: string }, permissions: string[], regions: ('CN' | 'EU')[]) => void
    }
    clearSession()
    setSession('admin-token', { id: 7, account: 'auditor', name: '审核员' }, ['audit:review:read'], ['EU'])
    await router.push('/dashboard')
    await router.isReady()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('redirects direct navigation without the route permission to the dashboard', async () => {
    await router.push('/system/admins')
    expect(router.currentRoute.value.path).toBe('/dashboard')

    await router.push('/audit/reviews')
    expect(router.currentRoute.value.path).toBe('/audit/reviews')
    expect(scrollTo).toHaveBeenCalledWith({ top: 0 })
  })

  it('guards the basic data route with the geodata read permission', async () => {
    await router.push('/data/meta')
    expect(router.currentRoute.value.path).toBe('/dashboard')

    const { setSession } = useAdminSession() as unknown as {
      setSession: (token: string, profile: { id: number; account: string; name: string }, permissions: string[], regions: ('CN' | 'EU')[]) => void
    }
    setSession(
      'admin-token',
      { id: 7, account: 'auditor', name: '审核员' },
      ['audit:review:read', 'data:geo:read'],
      ['EU'],
    )

    await router.push('/data/meta')
    expect(router.currentRoute.value.path).toBe('/data/meta')
  })
})
