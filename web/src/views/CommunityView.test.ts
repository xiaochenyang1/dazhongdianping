import { createApp, defineComponent, nextTick } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const communityMocks = vi.hoisted(() => ({ fetchPosts: vi.fn(), fetchPost: vi.fn(), fetchPostComments: vi.fn() }))
vi.mock('@/services/community', () => communityMocks)

import CommunityView from './CommunityView.vue'
import PostDetailView from './PostDetailView.vue'

const EmptyView = defineComponent({ template: '<div />' })
async function flushView() { await Promise.resolve(); await Promise.resolve(); await nextTick() }

async function mountCommunityView(host: HTMLElement) {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/community', component: CommunityView },
      { path: '/community/posts/:id', component: EmptyView },
      { path: '/users/:id', component: EmptyView },
      { path: '/groups', component: EmptyView },
      { path: '/topics', component: EmptyView },
    ],
  })
  const app = createApp(CommunityView)
  await router.push('/community')
  await router.isReady()
  app.use(router)
  app.mount(host)
  return app
}

describe('read-only community views', () => {
  beforeEach(() => { communityMocks.fetchPosts.mockReset(); communityMocks.fetchPost.mockReset(); communityMocks.fetchPostComments.mockReset() })

  it('renders the public feed with app guidance and no PC interactions', async () => {
    communityMocks.fetchPosts.mockResolvedValue({ list: [{ id: 7, userId: 9, userName: '伦敦小王', title: '伦敦周末市场指南', content: '周六上午选择最多。', contentType: 1, likeCount: 3, commentCount: 1, images: [], topics: ['伦敦生活'], createdAt: '2026-07-16' }], total: 1, page: 1, pageSize: 12, hasMore: false })
    const host = document.createElement('div'); const app = await mountCommunityView(host); await flushView()
    expect(host.textContent).toContain('伦敦周末市场指南'); expect(host.textContent).toContain('下载 APP 参与互动')
    expect([...host.querySelectorAll('button, a')].map((element) => element.textContent)).not.toEqual(expect.arrayContaining(['写帖子', '点赞', '发私信']))
    app.unmount()
  })

  it('renders a read-only post detail', async () => {
    communityMocks.fetchPost.mockResolvedValue({ id: 7, userId: 9, userName: '伦敦小王', title: '伦敦周末市场指南', content: '周六上午选择最多。', contentType: 1, likeCount: 3, commentCount: 1, images: [], topics: ['伦敦生活'], createdAt: '2026-07-16' })
    communityMocks.fetchPostComments.mockResolvedValue({ list: [{ id: 1, postId: 7, userId: 10, userName: '读者', content: '很实用', createdAt: '2026-07-16' }], total: 1, page: 1, pageSize: 50, hasMore: false })
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/users/:id', component: EmptyView }] })
    await router.push('/users/1'); await router.isReady()
    const host = document.createElement('div'); const app = createApp(PostDetailView, { postId: 7 }); app.use(router); app.mount(host); await flushView()
    expect(host.textContent).toContain('周六上午选择最多'); expect(host.textContent).toContain('很实用'); expect(host.textContent).not.toContain('点赞')
    app.unmount()
  })
})
