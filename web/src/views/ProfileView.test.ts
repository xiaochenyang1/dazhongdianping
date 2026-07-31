import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const authMocks = vi.hoisted(() => ({
  applyCurrentUserExpertCertification: vi.fn(),
  bindCurrentUserAccount: vi.fn(),
  fetchCurrentUser: vi.fn(),
  sendAuthCode: vi.fn(),
  updateCurrentUserPassword: vi.fn(),
  updateCurrentUserProfile: vi.fn(),
}))

const sessionMocks = vi.hoisted(() => ({
  state: {
    currentUser: null as Record<string, unknown> | null,
  },
  setCurrentUser: vi.fn((user: Record<string, unknown>) => {
    sessionMocks.state.currentUser = user
  }),
}))

const routeState = vi.hoisted(() => ({
  query: {} as Record<string, string>,
}))

vi.mock('@/services/auth', () => authMocks)
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => sessionMocks,
}))
vi.mock('@/lib/device-id', () => ({
  getBrowserDeviceId: () => 'profile-test-device',
}))
vi.mock('vue-router', () => ({
  useRoute: () => routeState,
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path"><slot /></a>',
  },
}))

import ProfileView from './ProfileView.vue'

const RouterLinkStub = {
  props: ['to'],
  template: '<a :href="typeof to === \'string\' ? to : to.path"><slot /></a>',
}

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(ProfileView)
  app.component('RouterLink', RouterLinkStub)
  app.mount(host)
  return { app, host }
}

describe('ProfileView', () => {
  beforeEach(() => {
    Object.values(authMocks).forEach((mock) => mock.mockReset())
    sessionMocks.setCurrentUser.mockClear()
    sessionMocks.state.currentUser = null
    useAppContext().setRegion('CN')
    routeState.query = { expert: 'approved' }
    authMocks.fetchCurrentUser.mockResolvedValue({
      id: 9,
      nickname: '巴黎探店老炮',
      avatar: '',
      gender: 0,
      signature: '',
      hasPassword: true,
      expertCertification: {
        status: 2,
        statusText: '已通过',
        reason: '常住巴黎写探店',
        badge: { code: 'local_expert', label: '本地达人' },
        submittedAt: '2026-07-25 10:00:00',
        reviewedAt: '2026-07-25 11:00:00',
        rejectReason: '',
      },
    })
  })

  it('loads profile and shows expert audit result banner from notification query', async () => {
    const { app, host } = mount()
    await flush()

    expect(authMocks.fetchCurrentUser).toHaveBeenCalled()
    expect(host.textContent).toContain('本地达人')
    expect(host.textContent).toContain('已通过')
    expect(host.querySelector('[data-testid="expert-audit-banner"]')?.textContent).toContain(
      '平台已通过你的本地达人认证',
    )
    app.unmount()
  })

  it('localizes expert status and reloads account data for EU', async () => {
    useAppContext().setRegion('EU')
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('My profile')
    expect(host.textContent).toContain('Local expert')
    expect(host.textContent).toContain('Approved')
    expect(host.textContent).toContain('25/07/2026 10:00')
    expect(host.querySelector('[data-testid="expert-audit-banner"]')?.textContent).toContain(
      'certification was approved',
    )
    expect(host.textContent).not.toContain('已通过')

    useAppContext().setRegion('CN')
    await flush()
    expect(authMocks.fetchCurrentUser).toHaveBeenCalledTimes(2)
    app.unmount()
  })
})
