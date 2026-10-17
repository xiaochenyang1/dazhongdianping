import { beforeEach, describe, expect, it, vi } from 'vitest'
const launchMocks = vi.hoisted(() => ({ load: vi.fn() }))
vi.mock('@/composables/useLaunchCapabilities', async importOriginal => ({
  ...await importOriginal<typeof import('@/composables/useLaunchCapabilities')>(),
  loadLaunchCapabilities: launchMocks.load,
}))
import { useAppContext } from '@/composables/useAppContext'
import router from '@/router'
import { useUserSession } from '@/composables/useUserSession'

describe('auth guarded routes', () => {
  beforeEach(async () => {
    window.scrollTo = () => {}
    useAppContext().setRegion('CN')
    launchMocks.load.mockResolvedValue({ region: 'EU', creatorRewards: false, seckill: false, groupBuy: false })
    localStorage.clear()
    const session = useUserSession()
    session.clearSession()
    session.closeAuthDialog()
    await router.replace('/')
  })

  it.each(['/user/creator', '/marketing/seckill', '/marketing/groupbuy'])('blocks deferred EU deep link %s before asking for login', async path => {
    useAppContext().setRegion('EU')
    await router.push(path)
    expect(router.currentRoute.value.name).toBe('home')
    expect(useUserSession().state.authDialogOpen).toBe(false)
    expect(launchMocks.load).toHaveBeenCalledWith('EU')
  })

  it('uses the normal authentication flow when a capability is explicitly enabled', async () => {
    useAppContext().setRegion('EU')
    launchMocks.load.mockResolvedValue({ region: 'EU', creatorRewards: true, seckill: false, groupBuy: false })
    await router.push('/user/creator')
    expect(useUserSession().state.authDialogOpen).toBe(true)
    expect(useUserSession().state.redirectTo).toBe('/user/creator')
  })

  it('opens login dialog and preserves redirect when visiting a protected page as guest', async () => {
    const { state } = useUserSession()

    await router.push('/user/profile').catch(() => undefined)

    expect(state.authDialogOpen).toBe(true)
    expect(state.redirectTo).toBe('/user/profile')
  })

  it('protects the privacy center route for guests', async () => {
    const { state } = useUserSession()

    await router.push('/user/privacy').catch(() => undefined)

    expect(state.authDialogOpen).toBe(true)
    expect(state.redirectTo).toBe('/user/privacy')
  })

  it('protects the daily check-in route for guests', async () => {
    const { state } = useUserSession()

    await router.push('/user/check-in').catch(() => undefined)

    expect(state.authDialogOpen).toBe(true)
    expect(state.redirectTo).toBe('/user/check-in')
  })

  it('protects the points mall route for guests', async () => {
    const { state } = useUserSession()

    await router.push('/user/points-mall').catch(() => undefined)

    expect(state.authDialogOpen).toBe(true)
    expect(state.redirectTo).toBe('/user/points-mall')
  })

  it('stores pending guest action until login completion consumes it', async () => {
    const { state, openAuthDialog, consumePendingAuthAction } = useUserSession()
    let executed = false

    openAuthDialog({
      mode: 'password',
      redirectTo: '/reviews/1',
      afterLogin: () => {
        executed = true
      },
    })

    const pendingAction = consumePendingAuthAction()
    await pendingAction?.()

    expect(state.authDialogOpen).toBe(true)
    expect(executed).toBe(true)
    expect(consumePendingAuthAction()).toBeUndefined()
  })
})
