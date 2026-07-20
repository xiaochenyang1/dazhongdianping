import { createApp, defineComponent, nextTick } from 'vue'
import { describe, expect, it, vi } from 'vitest'

const authMocks = vi.hoisted(() => ({ fetchUserFollowers: vi.fn(), fetchUserFollowing: vi.fn() }))
vi.mock('@/services/auth', () => authMocks)
import UserRelationshipsView from './UserRelationshipsView.vue'

const RouterLinkStub = defineComponent({ props: ['to'], template: '<a><slot /></a>' })

describe('UserRelationshipsView', () => {
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
})
