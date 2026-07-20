import { beforeEach, describe, expect, it } from 'vitest'
import { useMerchantSession } from './useMerchantSession'

describe('merchant session', () => {
  beforeEach(() => localStorage.clear())

  it('persists token, account and region then clears them', () => {
    const session = useMerchantSession()
    session.setRegion('CN')
    session.setSession({ accessToken: 'token-1', merchantId: 7, account: 'merchant@example.com', region: 'EU' })
    expect(session.state.token).toBe('token-1')
    expect(session.state.merchantId).toBe(7)
    expect(session.state.region).toBe('EU')
    expect(localStorage.getItem('dzdp:merchant-token')).toBe('token-1')
    expect(localStorage.getItem('dzdp:merchant-region')).toBe('EU')

    session.clearSession()
    expect(session.state.token).toBeUndefined()
    expect(localStorage.getItem('dzdp:merchant-token')).toBeNull()
  })
})
