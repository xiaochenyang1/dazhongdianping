import { beforeEach, describe, expect, it } from 'vitest'
import { useAdminSession } from './useAdminSession'

describe('useAdminSession', () => {
  beforeEach(() => {
    localStorage.clear()
    const { clearSession, setRegion } = useAdminSession()
    clearSession()
    setRegion('CN')
  })

  it('persists regions and refreshes the current identity from the server', () => {
    const session = useAdminSession() as unknown as {
      state: { token?: string; profile?: { id: number; account: string; name: string }; permissions: string[]; regions: ('CN' | 'EU')[]; region: 'CN' | 'EU' }
      setSession: (token: string, profile: { id: number; account: string; name: string }, permissions: string[], regions: ('CN' | 'EU')[]) => void
      updateIdentity: (identity: { profile: { id: number; account: string; name: string }; permissions: string[]; regions: ('CN' | 'EU')[] }) => void
      clearSession: () => void
    }

    session.setSession('admin-token', { id: 7, account: 'eu.reader', name: 'EU 只读员' }, ['data:shop:read'], ['EU'])

    expect(session.state.regions).toEqual(['EU'])
    expect(session.state.region).toBe('EU')
    expect(localStorage.getItem('dzdp:admin-regions')).toBe(JSON.stringify(['EU']))

    session.updateIdentity({
      profile: { id: 7, account: 'eu.reader', name: 'EU 新名称' },
      permissions: ['audit:review:read'],
      regions: ['CN'],
    })

    expect(session.state.profile?.name).toBe('EU 新名称')
    expect(session.state.permissions).toEqual(['audit:review:read'])
    expect(session.state.regions).toEqual(['CN'])
    expect(session.state.region).toBe('CN')

    session.clearSession()
    expect(session.state.regions).toEqual([])
    expect(localStorage.getItem('dzdp:admin-regions')).toBeNull()
  })
})
