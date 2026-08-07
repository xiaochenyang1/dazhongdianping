import { beforeEach, describe, expect, it } from 'vitest'
import router from '@/router'
import { useUserSession } from '@/composables/useUserSession'

describe('auth guarded routes', () => {
  beforeEach(async () => {
    window.scrollTo = () => {}
    localStorage.clear()
    const session = useUserSession()
    session.clearSession()
    session.closeAuthDialog()
    await router.replace('/')
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
