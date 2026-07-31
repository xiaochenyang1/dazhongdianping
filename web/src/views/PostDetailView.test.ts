import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const communityMocks = vi.hoisted(() => ({
  fetchPost: vi.fn(),
  fetchPostComments: vi.fn(),
}))

const routeState = vi.hoisted(() => ({
  query: {} as Record<string, string>,
}))

vi.mock('@/services/community', () => communityMocks)
vi.mock('vue-router', () => ({
  useRoute: () => routeState,
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path"><slot /></a>',
  },
}))

import PostDetailView from './PostDetailView.vue'

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

function mount(postId = 88) {
  const host = document.createElement('div')
  const app = createApp(PostDetailView, { postId })
  app.component('RouterLink', RouterLinkStub)
  app.mount(host)
  return { app, host }
}

describe('PostDetailView', () => {
  beforeEach(() => {
    communityMocks.fetchPost.mockReset()
    communityMocks.fetchPostComments.mockReset()
    routeState.query = { audit: 'approved' }
    communityMocks.fetchPost.mockResolvedValue({
      id: 88,
      userId: 9,
      userName: '作者',
      title: '伦敦周末早午餐避坑指南',
      content: '别踩坑',
      topics: ['早午餐'],
      images: [],
      likeCount: 0,
      commentCount: 0,
      createdAt: '2026-07-25 12:00:00',
    })
    communityMocks.fetchPostComments.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 20, hasMore: false })
  })

  it('shows post audit result banner from notification query', async () => {
    const { app, host } = mount()
    await flush()

    expect(communityMocks.fetchPost).toHaveBeenCalledWith(88)
    expect(host.textContent).toContain('伦敦周末早午餐避坑指南')
    expect(host.querySelector('[data-testid="post-audit-banner"]')?.textContent).toContain(
      '平台已通过你的帖子',
    )
    app.unmount()
  })

  it('uses the native share contract when the browser provides it', async () => {
    const share = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'share', { configurable: true, value: share })

    const { app, host } = mount()
    await flush()
    host.querySelector<HTMLButtonElement>('[data-testid="share-post"]')?.click()
    await flush()

    expect(share).toHaveBeenCalledWith(
      expect.objectContaining({
        title: '伦敦周末早午餐避坑指南',
        url: expect.any(String),
      }),
    )
    expect(host.querySelector('[data-testid="share-post-message"]')?.textContent).toContain(
      '分享链接已准备好',
    )
    app.unmount()
    Reflect.deleteProperty(navigator, 'share')
  })
})
