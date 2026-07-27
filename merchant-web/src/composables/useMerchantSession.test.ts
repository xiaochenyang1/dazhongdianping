import { beforeEach, describe, expect, it } from 'vitest'
import { useMerchantSession } from './useMerchantSession'

describe('merchant session', () => {
  beforeEach(() => localStorage.clear())

  it('persists the fixed region and clears merchant identity', () => {
    const session = useMerchantSession()
    session.setSession({ accessToken: 'token-1', merchantId: 7, account: 'merchant@example.com', region: 'EU' })
    expect(session.state.token).toBe('token-1')
    expect(session.state.merchantId).toBe(7)
    expect(session.state.region).toBe('EU')
    expect(localStorage.getItem('dzdp:merchant-token')).toBe('token-1')
    expect(localStorage.getItem('dzdp:merchant-region')).toBe('EU')

    session.clearSession()
    expect(session.state.token).toBeUndefined()
    expect(session.state.merchantId).toBeUndefined()
    expect(session.state.account).toBeUndefined()
    expect(session.state.region).toBe('EU')
    expect(localStorage.getItem('dzdp:merchant-token')).toBeNull()
  })

  it('does not clear a replacement login for a stale request snapshot', () => {
    const session = useMerchantSession()
    session.setSession({
      accessToken: 'old-token',
      merchantId: 7,
      account: 'old@example.com',
      region: 'EU',
    })
    const stale = session.snapshotSession()

    session.setSession({
      accessToken: 'replacement-token',
      merchantId: 8,
      account: 'replacement@example.com',
      region: 'CN',
    })

    expect(session.clearSessionIfCurrent(stale)).toBe(false)
    expect(session.state.token).toBe('replacement-token')
    expect(session.state.merchantId).toBe(8)
    expect(session.state.region).toBe('CN')
  })
})
