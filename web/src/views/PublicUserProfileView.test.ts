import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const authMocks = vi.hoisted(() => ({
  fetchPublicUserProfile: vi.fn(),
}))

vi.mock('@/services/auth', () => authMocks)
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({
    state: {
      currentUser: undefined,
    },
  }),
}))

import { useAppContext } from '@/composables/useAppContext'
import PublicUserProfileView from './PublicUserProfileView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('PublicUserProfileView', () => {
  beforeEach(() => {
    authMocks.fetchPublicUserProfile.mockReset()
    localStorage.clear()
    useAppContext().setRegion('CN')
  })

  it('reloads the public profile when the active region changes', async () => {
    authMocks.fetchPublicUserProfile
      .mockResolvedValueOnce({
        id: 9002,
        nickname: '欧洲咖啡客',
        avatar: '',
        signature: '',
        preferredRegion: 'EU',
        level: 3,
        points: 5,
        growthValue: 80,
        reviewCount: 2,
        followerCount: 18,
        followingCount: 7,
        followedByCurrentUser: false,
      })
      .mockResolvedValueOnce({
        id: 9002,
        nickname: '欧洲咖啡客',
        avatar: '',
        signature: '',
        preferredRegion: 'EU',
        level: 3,
        points: 5,
        growthValue: 80,
        reviewCount: 1,
        followerCount: 18,
        followingCount: 7,
        followedByCurrentUser: false,
      })

    const host = document.createElement('div')
    const app = createApp(PublicUserProfileView, { userId: 9002 })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(authMocks.fetchPublicUserProfile).toHaveBeenCalledTimes(1)
    expect(authMocks.fetchPublicUserProfile).toHaveBeenNthCalledWith(1, 9002)
    expect(host.textContent).toContain('公开点评 2 条')
    expect(host.textContent).toContain('粉丝 18')
    expect(host.textContent).toContain('关注 7')
    expect(host.textContent).not.toContain('取消关注')

    useAppContext().setRegion('EU')
    await flushView()

    expect(authMocks.fetchPublicUserProfile).toHaveBeenCalledTimes(2)
    expect(authMocks.fetchPublicUserProfile).toHaveBeenNthCalledWith(2, 9002)
    expect(host.textContent).toContain('公开点评 1 条')
    app.unmount()
  })
})
