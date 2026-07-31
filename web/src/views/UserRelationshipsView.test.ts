import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const authMocks = vi.hoisted(() => ({ fetchUserFollowers: vi.fn(), fetchUserFollowing: vi.fn() }))
vi.mock('@/services/auth', () => authMocks)
import UserRelationshipsView from './UserRelationshipsView.vue'

const RouterLinkStub = defineComponent({ props: ['to'], template: '<a><slot /></a>' })

describe('UserRelationshipsView', () => {
  beforeEach(() => {
    authMocks.fetchUserFollowers.mockReset()
    authMocks.fetchUserFollowing.mockReset()
    useAppContext().setRegion('CN')
  })

  it('renders a read-only follower list without follow actions', async () => {
    authMocks.fetchUserFollowers.mockResolvedValue({ list: [{ id: 9, nickname: '伦敦小王', avatar: '', signature: '咖啡探店', level: 3, followerCount: 12, followedByCurrentUser: false, followedAt: '2026-07-17 09:00:00' }], total: 1, page: 1, pageSize: 20, hasMore: false })
    const host = document.createElement('div')
    const app = createApp(UserRelationshipsView, { userId: 8, mode: 'followers' })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await Promise.resolve(); await Promise.resolve(); await nextTick()
    expect(host.textContent).toContain('粉丝 1 人')
    expect(host.textContent).toContain('伦敦小王')
    expect(host.textContent).not.toContain('关注按钮')
    app.unmount()
  })

  it('localizes and reloads the relationship list for EU', async () => {
    authMocks.fetchUserFollowers.mockResolvedValue({ list: [{ id: 9, nickname: 'Alex', avatar: '', signature: '', level: 3, followerCount: 12, followedByCurrentUser: false, followedAt: '2026-07-17 09:00:00' }], total: 1, page: 1, pageSize: 20, hasMore: false })
    useAppContext().setRegion('EU')
    const host = document.createElement('div')
    const app = createApp(UserRelationshipsView, { userId: 8, mode: 'followers' })
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await Promise.resolve(); await Promise.resolve(); await nextTick()

    expect(host.textContent).toContain('1 follower')
    expect(host.textContent).toContain('12 followers')
    expect(host.textContent).toContain('17/07/2026 09:00')

    useAppContext().setRegion('CN')
    await Promise.resolve(); await Promise.resolve(); await nextTick()
    expect(authMocks.fetchUserFollowers).toHaveBeenCalledTimes(2)
    app.unmount()
  })
})
