import { createApp, defineComponent, nextTick, type Component } from 'vue'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'
import { communityStringsForRegion } from '@/core/web_community_localizations'
import type { PublicCircle } from '@/services/circle'
import type { PublicTopic } from '@/services/topic'
import type { CommunityPost } from '@/types/community'

const communityMocks = vi.hoisted(() => ({
  fetchPosts: vi.fn(),
  fetchPost: vi.fn(),
  fetchPostComments: vi.fn(),
}))
const circleMocks = vi.hoisted(() => ({
  fetchCircles: vi.fn(),
  fetchCircle: vi.fn(),
  fetchCirclePosts: vi.fn(),
}))
const topicMocks = vi.hoisted(() => ({
  fetchTopics: vi.fn(),
  fetchHotTopics: vi.fn(),
  fetchTopic: vi.fn(),
  fetchTopicPosts: vi.fn(),
}))

vi.mock('@/services/community', () => communityMocks)
vi.mock('@/services/circle', () => circleMocks)
vi.mock('@/services/topic', () => topicMocks)

import CommunityView from './CommunityView.vue'
import PostDetailView from './PostDetailView.vue'
import CircleListView from './CircleListView.vue'
import CircleDetailView from './CircleDetailView.vue'
import TopicListView from './TopicListView.vue'
import TopicDetailView from './TopicDetailView.vue'

const EmptyView = defineComponent({ template: '<div />' })

interface Page<T> {
  list: T[]
  total: number
  page: number
  pageSize: number
  hasMore: boolean
}

function page<T>(list: T[]): Page<T> {
  return { list, total: list.length, page: 1, pageSize: 30, hasMore: false }
}

function post(id: number, title: string): CommunityPost {
  return {
    id,
    userId: 9,
    userName: 'Author',
    title,
    content: `${title} content`,
    contentType: 1,
    likeCount: 1,
    commentCount: 1,
    images: [],
    topics: [],
    createdAt: '2026-07-17 10:00:00',
  }
}

function circle(id: number, region: 'CN' | 'EU', name: string): PublicCircle {
  return {
    id,
    region,
    name,
    description: `${name} description`,
    coverUrl: '',
    memberCount: 1,
    postCount: 1,
    sort: 0,
    status: 1,
    joinedByCurrentUser: false,
  }
}

function topic(id: number, region: 'CN' | 'EU', name: string): PublicTopic {
  return {
    id,
    region,
    name,
    postCount: 1,
    followerCount: 1,
    recommended: true,
    pinnedSort: 0,
    followedByCurrentUser: false,
    hotScore: 10,
    postCount7d: 1,
    likeCount7d: 1,
    commentCount7d: 1,
    calculatedAt: '2026-07-17 19:00:00',
  }
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

async function mount(component: Component, props: Record<string, unknown> = {}) {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: EmptyView },
      { path: '/users/:id', component: EmptyView },
      { path: '/community/posts/:id', component: EmptyView },
      { path: '/groups', component: EmptyView },
      { path: '/groups/:id', component: EmptyView },
      { path: '/topics', component: EmptyView },
      { path: '/topics/:id', component: EmptyView },
    ],
  })
  await router.push('/')
  await router.isReady()
  const host = document.createElement('div')
  const app = createApp(component, props)
  app.use(router)
  app.mount(host)
  await flushView()
  return { app, host }
}

describe('community views regional reloads', () => {
  beforeEach(() => {
    Object.values(communityMocks).forEach((mock) => mock.mockReset())
    Object.values(circleMocks).forEach((mock) => mock.mockReset())
    Object.values(topicMocks).forEach((mock) => mock.mockReset())
    localStorage.clear()
    useAppContext().setRegion('EU')
  })

  it('reloads the community feed when the region changes', async () => {
    communityMocks.fetchPosts
      .mockResolvedValueOnce(page([post(1, 'EU feed post')]))
      .mockResolvedValueOnce(page([post(2, 'CN feed post')]))

    const { app, host } = await mount(CommunityView)
    expect(host.textContent).toContain('EU feed post')

    useAppContext().setRegion('CN')
    await flushView()

    expect(communityMocks.fetchPosts).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('CN feed post')
    expect(host.textContent).not.toContain('EU feed post')
    app.unmount()
  })

  it('reloads a post and its comments when the region changes', async () => {
    communityMocks.fetchPost
      .mockResolvedValueOnce(post(7, 'EU post'))
      .mockResolvedValueOnce(post(7, 'CN post'))
    communityMocks.fetchPostComments
      .mockResolvedValueOnce(page([{ id: 1, postId: 7, userId: 1, userName: 'Reader', content: 'EU comment', parentId: 0, replies: [], createdAt: '2026-07-17' }]))
      .mockResolvedValueOnce(page([{ id: 2, postId: 7, userId: 2, userName: '读者', content: 'CN comment', parentId: 0, replies: [], createdAt: '2026-07-17' }]))

    const { app, host } = await mount(PostDetailView, { postId: 7 })
    expect(host.textContent).toContain('EU post')
    expect(host.textContent).toContain('EU comment')

    useAppContext().setRegion('CN')
    await flushView()

    expect(communityMocks.fetchPost).toHaveBeenCalledTimes(2)
    expect(communityMocks.fetchPostComments).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('CN post')
    expect(host.textContent).toContain('CN comment')
    expect(host.textContent).not.toContain('EU post')
    app.unmount()
  })

  it('reloads the circle list when the region changes', async () => {
    circleMocks.fetchCircles
      .mockResolvedValueOnce(page([circle(3, 'EU', 'EU circle')]))
      .mockResolvedValueOnce(page([circle(4, 'CN', 'CN circle')]))

    const { app, host } = await mount(CircleListView)
    expect(host.textContent).toContain('EU circle')

    useAppContext().setRegion('CN')
    await flushView()

    expect(circleMocks.fetchCircles).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('CN circle')
    expect(host.textContent).not.toContain('EU circle')
    app.unmount()
  })

  it('reloads circle details and posts when the region changes', async () => {
    circleMocks.fetchCircle
      .mockResolvedValueOnce(circle(3, 'EU', 'EU circle detail'))
      .mockResolvedValueOnce(circle(3, 'CN', 'CN circle detail'))
    circleMocks.fetchCirclePosts
      .mockResolvedValueOnce(page([post(7, 'EU circle post')]))
      .mockResolvedValueOnce(page([post(8, 'CN circle post')]))

    const { app, host } = await mount(CircleDetailView, { circleId: 3 })
    expect(host.textContent).toContain('EU circle detail')
    expect(host.textContent).toContain('EU circle post')

    useAppContext().setRegion('CN')
    await flushView()

    expect(circleMocks.fetchCircle).toHaveBeenCalledTimes(2)
    expect(circleMocks.fetchCirclePosts).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('CN circle detail')
    expect(host.textContent).toContain('CN circle post')
    expect(host.textContent).not.toContain('EU circle detail')
    app.unmount()
  })

  it('reloads topic details and posts when the region changes', async () => {
    topicMocks.fetchTopic
      .mockResolvedValueOnce(topic(31, 'EU', 'EU topic detail'))
      .mockResolvedValueOnce(topic(31, 'CN', 'CN topic detail'))
    topicMocks.fetchTopicPosts
      .mockResolvedValueOnce(page([post(7, 'EU topic post')]))
      .mockResolvedValueOnce(page([post(8, 'CN topic post')]))

    const { app, host } = await mount(TopicDetailView, { topicId: 31 })
    expect(host.textContent).toContain('EU topic detail')
    expect(host.textContent).toContain('EU topic post')

    useAppContext().setRegion('CN')
    await flushView()

    expect(topicMocks.fetchTopic).toHaveBeenCalledTimes(2)
    expect(topicMocks.fetchTopicPosts).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('CN topic detail')
    expect(host.textContent).toContain('CN topic post')
    expect(host.textContent).not.toContain('EU topic detail')
    app.unmount()
  })

  it('reloads the current topic mode and ignores an older regional response', async () => {
    const pendingHot: Array<(value: Page<PublicTopic>) => void> = []
    topicMocks.fetchTopics.mockResolvedValue(page([topic(31, 'EU', 'EU recommended')]))
    topicMocks.fetchHotTopics.mockImplementation(() => new Promise<Page<PublicTopic>>((resolve) => pendingHot.push(resolve)))

    const { app, host } = await mount(TopicListView)
    const hotButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('Last 7 days'))
    if (!hotButton) throw new Error('Missing hot topic mode button')
    hotButton.click()
    await nextTick()

    useAppContext().setRegion('CN')
    await nextTick()

    expect(topicMocks.fetchTopics).toHaveBeenCalledTimes(1)
    expect(topicMocks.fetchHotTopics).toHaveBeenCalledTimes(2)

    pendingHot[1]?.(page([topic(41, 'CN', 'CN hot topic')]))
    await flushView()
    pendingHot[0]?.(page([topic(32, 'EU', 'EU stale hot topic')]))
    await flushView()

    expect(host.textContent).toContain('CN hot topic')
    expect(host.textContent).not.toContain('EU stale hot topic')
    expect(host.textContent).toContain('最近 7 天热榜')
    app.unmount()
  })

  it('uses natural singular English counts', () => {
    const copy = communityStringsForRegion('EU')
    expect(copy.feed.likes(1)).toBe('1 like')
    expect(copy.feed.comments(1)).toBe('1 comment')
    expect(copy.circles.counts(1, 1)).toBe('1 member · 1 post')
    expect(copy.topics.composition(1, 1, 1)).toBe('1 post · 1 like · 1 comment')
    expect(copy.topics.audience(1, 1)).toBe('1 follower · 1 public post')
    expect(copy.topics.followerCount(1)).toBe('1 follower')
    expect(copy.topics.postCount(1)).toBe('1 public post')
    expect(copy.topics.likes(1)).toBe('1 like')
    expect(copy.topics.comments(1)).toBe('1 comment')
  })

  it('uses a natural topic detail fallback description before data loads', async () => {
    topicMocks.fetchTopic.mockImplementation(() => new Promise(() => undefined))
    topicMocks.fetchTopicPosts.mockResolvedValue(page([]))

    const { app } = await mount(TopicDetailView, { topicId: 31 })

    expect(document.head.querySelector('meta[name="description"]')?.getAttribute('content')).toBe(
      'View topic activity and public community posts.',
    )
    app.unmount()
  })
})
