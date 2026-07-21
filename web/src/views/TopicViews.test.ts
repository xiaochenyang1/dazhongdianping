import { createApp, defineComponent, h, nextTick, ref } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchTopics: vi.fn(),
  fetchHotTopics: vi.fn(),
  fetchTopic: vi.fn(),
  fetchTopicPosts: vi.fn(),
}))

vi.mock('@/services/topic', () => mocks)
vi.mock('vue-router', () => ({ RouterLink: { props: ['to'], template: '<a :data-to="to"><slot /></a>' } }))

import TopicListView from './TopicListView.vue'
import TopicDetailView from './TopicDetailView.vue'

const RouterLinkStub = defineComponent({ props: ['to'], template: '<a :data-to="to"><slot /></a>' })

async function mount(component: object, props = {}) {
  const host = document.createElement('div')
  const app = createApp(component, props)
  app.component('RouterLink', RouterLinkStub)
  app.mount(host)
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  return { host, app }
}

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

const topic = {
  id: 31,
  region: 'EU' as const,
  name: '伦敦咖啡',
  postCount: 12,
  followerCount: 88,
  recommended: true,
  pinnedSort: 0,
  followedByCurrentUser: false,
  hotScore: 169,
  postCount7d: 2,
  likeCount7d: 3,
  commentCount7d: 4,
  calculatedAt: '2026-07-17 19:00:00',
}

describe('topic read-only views', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchTopics.mockResolvedValue({ list: [topic], total: 1, page: 1, pageSize: 30, hasMore: false })
    mocks.fetchHotTopics.mockResolvedValue({ list: [topic], total: 1, page: 1, pageSize: 30, hasMore: false })
    mocks.fetchTopic.mockResolvedValue(topic)
    mocks.fetchTopicPosts.mockResolvedValue({
      list: [{
        id: 7,
        userId: 9,
        userName: '伦敦小王',
        title: '周末咖啡地图',
        content: '三家新店实测。',
        likeCount: 2,
        commentCount: 1,
        topics: ['伦敦咖啡'],
        createdAt: '2026-07-17 10:00:00',
      }],
      total: 1,
      page: 1,
      pageSize: 30,
      hasMore: false,
    })
  })

  it('switches from recommended topics to the seven-day hot ranking', async () => {
    const { host, app } = await mount(TopicListView)
    expect(mocks.fetchTopics).toHaveBeenCalledWith('recommended')
    expect(host.textContent).toContain('伦敦咖啡')
    expect(host.textContent).not.toContain('关注话题')

    const hotButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('最近 7 天热榜'))
    if (!hotButton) throw new Error('缺少热榜切换按钮')
    hotButton.click()
    await Promise.resolve()
    await Promise.resolve()
    await nextTick()

    expect(mocks.fetchHotTopics).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('TOP 1')
    expect(host.textContent).toContain('热度 169')
    expect(host.textContent).toContain('2 帖 · 3 赞 · 4 评论')
    expect(host.textContent).not.toContain('发布帖子')
    app.unmount()
  })

  it('publishes CollectionPage metadata for the public topic index', async () => {
    const { app } = await mount(TopicListView)
    const canonical = `${window.location.origin}/topics`
    expect(document.head.querySelector('link[rel="canonical"]')?.getAttribute('href')).toBe(canonical)
    expect(document.head.querySelector('meta[property="og:url"]')?.getAttribute('content')).toBe(canonical)
    const schema = JSON.parse(document.head.querySelector('script[type="application/ld+json"]')?.textContent ?? '{}')
    expect(schema).toMatchObject({ '@type': 'CollectionPage', url: canonical })
    expect(schema.mainEntity.itemListElement[0]).toMatchObject({ position: 1, url: `${window.location.origin}/topics/31` })
    app.unmount()
  })

  it('renders topic detail posts and author links without write controls', async () => {
    const { host, app } = await mount(TopicDetailView, { topicId: 31 })
    expect(host.textContent).toContain('88 人关注')
    expect(host.textContent).toContain('周末咖啡地图')
    expect(host.querySelector('a[data-to="/community/posts/7"]')).not.toBeNull()
    expect(host.querySelector('a[data-to="/users/9"]')).not.toBeNull()
    expect(host.textContent).not.toContain('关注话题')
    expect(host.textContent).not.toContain('创建话题')
    expect(host.textContent).not.toContain('发布帖子')
    app.unmount()
  })

  it('publishes CollectionPage metadata and JSON-LD for a public topic', async () => {
    const { app } = await mount(TopicDetailView, { topicId: 31 })
    const canonical = document.head.querySelector('link[rel="canonical"]')
    expect(canonical?.getAttribute('href')).toBe(`${window.location.origin}/topics/31`)
    expect(document.title).toContain('伦敦咖啡')
    const schema = JSON.parse(document.head.querySelector('script[type="application/ld+json"]')?.textContent ?? '{}')
    expect(schema).toMatchObject({ '@type': 'CollectionPage', name: '伦敦咖啡', url: canonical?.getAttribute('href') })
    expect(schema.mainEntity.itemListElement[0]).toMatchObject({ position: 1, url: `${window.location.origin}/community/posts/7` })
    app.unmount()
  })

  it('reloads a reused topic route, clears old content, and ignores stale responses', async () => {
    const pending = new Map<number, (value: typeof topic) => void>()
    mocks.fetchTopic.mockImplementation((id: number) => new Promise<typeof topic>((resolve) => pending.set(id, resolve)))
    mocks.fetchTopicPosts.mockResolvedValue({ list: [], total: 0, page: 1, pageSize: 30, hasMore: false })
    const topicId = ref(31)
    const Root = defineComponent({ setup: () => () => h(TopicDetailView, { topicId: topicId.value }) })
    const host = document.createElement('div')
    const app = createApp(Root)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    pending.get(31)?.({ ...topic, id: 31, name: '话题 31' })
    await flushView()
    expect(host.textContent).toContain('话题 31')

    topicId.value = 32
    await flushView()
    expect(host.textContent).not.toContain('话题 31')
    topicId.value = 33
    await flushView()
    expect(mocks.fetchTopic).toHaveBeenCalledWith(32)
    expect(mocks.fetchTopic).toHaveBeenCalledWith(33)

    pending.get(33)?.({ ...topic, id: 33, name: '话题 33' })
    await flushView()
    pending.get(32)?.({ ...topic, id: 32, name: '话题 32' })
    await flushView()

    expect(host.textContent).toContain('话题 33')
    expect(host.textContent).not.toContain('话题 32')
    expect(document.head.querySelector('link[rel="canonical"]')?.getAttribute('href')).toBe(`${window.location.origin}/topics/33`)
    app.unmount()
  })
})
