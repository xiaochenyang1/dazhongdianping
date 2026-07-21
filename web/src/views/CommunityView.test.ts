import { createApp, defineComponent, h, nextTick, ref } from 'vue'
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
    expect(host.querySelector('a[href="/community/posts/7"]')).not.toBeNull()
    expect(host.querySelector('a[href="/users/9"]')).not.toBeNull()
    expect(host.querySelector('a a')).toBeNull()
    app.unmount()
  })

  it('publishes an indexable CollectionPage for the public community feed', async () => {
    communityMocks.fetchPosts.mockResolvedValue({ list: [{ id: 7, userId: 9, userName: '伦敦小王', title: '伦敦周末市场指南', content: '周六上午选择最多。', contentType: 1, likeCount: 3, commentCount: 1, images: [], topics: ['伦敦生活'], createdAt: '2026-07-16' }], total: 1, page: 1, pageSize: 12, hasMore: false })
    const host = document.createElement('div'); const app = await mountCommunityView(host); await flushView()

    expect(document.head.querySelector('link[rel="canonical"]')?.getAttribute('href')).toBe(`${window.location.origin}/community`)
    expect(document.head.querySelector('meta[name="robots"]')?.getAttribute('content')).toBe('index,follow')
    const schema = JSON.parse(document.head.querySelector('script[type="application/ld+json"]')?.textContent ?? '{}')
    expect(schema).toMatchObject({ '@type': 'CollectionPage', url: `${window.location.origin}/community` })
    expect(schema.mainEntity.itemListElement[0]).toMatchObject({ position: 1, url: `${window.location.origin}/community/posts/7` })
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

  it('publishes canonical Article metadata for a public community post', async () => {
    communityMocks.fetchPost.mockResolvedValue({ id: 7, userId: 9, userName: '伦敦小王', title: '伦敦周末市场指南', content: '周六上午选择最多。', contentType: 1, likeCount: 3, commentCount: 1, images: ['https://cdn.example.test/market.jpg'], topics: ['伦敦生活'], createdAt: '2026-07-16' })
    communityMocks.fetchPostComments.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 50, hasMore: false })
    const router = createRouter({ history: createMemoryHistory(), routes: [{ path: '/users/:id', component: EmptyView }] })
    await router.push('/users/1'); await router.isReady()
    const host = document.createElement('div'); const app = createApp(PostDetailView, { postId: 7 }); app.use(router); app.mount(host); await flushView()

    const canonical = document.head.querySelector('link[rel="canonical"]')
    expect(canonical?.getAttribute('href')).toBe(`${window.location.origin}/community/posts/7`)
    const schema = JSON.parse(document.head.querySelector('script[type="application/ld+json"]')?.textContent ?? '{}')
    expect(schema).toMatchObject({ '@type': 'Article', headline: '伦敦周末市场指南', url: canonical?.getAttribute('href'), author: { '@type': 'Person', name: '伦敦小王' } })
    app.unmount()
  })

  it('reloads a reused post route and ignores stale responses from older post ids', async () => {
    const pending = new Map<number, { resolve: (value: any) => void; reject: (reason?: unknown) => void }>()
    communityMocks.fetchPost.mockImplementation((postId: number) => new Promise((resolve, reject) => {
      pending.set(postId, { resolve, reject })
    }))
    communityMocks.fetchPostComments.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 50, hasMore: false })

    const post = (id: number) => ({
      id,
      userId: 9,
      userName: '伦敦小王',
      title: `帖子 ${id}`,
      content: `内容 ${id}`,
      contentType: 1,
      likeCount: 0,
      commentCount: 0,
      images: [],
      topics: [],
      createdAt: '2026-07-16',
    })
    const postId = ref(7)
    const Root = defineComponent({ setup: () => () => h(PostDetailView, { postId: postId.value }) })
    const host = document.createElement('div')
    const app = createApp(Root)
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/', component: EmptyView },
        { path: '/users/:id', component: EmptyView },
      ],
    })
    await router.push('/')
    await router.isReady()
    app.use(router)
    app.mount(host)
    await flushView()

    pending.get(7)?.resolve(post(7))
    await flushView()
    expect(host.textContent).toContain('帖子 7')

    postId.value = 8
    await flushView()
    expect(host.textContent).not.toContain('帖子 7')
    postId.value = 9
    await flushView()
    expect(communityMocks.fetchPost).toHaveBeenCalledWith(8)
    expect(communityMocks.fetchPost).toHaveBeenCalledWith(9)

    pending.get(9)?.resolve(post(9))
    await flushView()
    pending.get(8)?.resolve(post(8))
    await flushView()

    expect(host.textContent).toContain('帖子 9')
    expect(host.textContent).not.toContain('帖子 8')
    expect(document.head.querySelector('link[rel="canonical"]')?.getAttribute('href')).toBe(`${window.location.origin}/community/posts/9`)
    app.unmount()
  })
})
