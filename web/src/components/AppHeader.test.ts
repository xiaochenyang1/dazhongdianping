import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const browseMocks = vi.hoisted(() => ({
  clearSearchHistory: vi.fn(),
  fetchHotSearchWords: vi.fn(),
  fetchSearchHistory: vi.fn(),
  fetchSearchSuggestions: vi.fn(),
}))

const routerMocks = vi.hoisted(() => ({
  push: vi.fn(),
}))

const notificationMocks = vi.hoisted(() => ({
  state: {
    items: [] as Array<Record<string, unknown>>,
    unreadCount: 0,
    connected: true,
    loading: false,
  },
  refresh: vi.fn(),
  connect: vi.fn(),
  disconnect: vi.fn(),
  markRead: vi.fn(),
}))

vi.mock('@/services/browse', () => browseMocks)
vi.mock('@/services/auth', () => ({
  logoutUser: vi.fn(),
}))
vi.mock('@/composables/useNotifications', () => ({
  useNotifications: () => notificationMocks,
}))
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({
    state: {
      accessToken: 'test-token',
      currentUser: {
        id: 9001,
        nickname: '阿木',
        level: 4,
        preferredRegion: 'CN',
      },
    },
    openAuthDialog: vi.fn(),
    clearSession: vi.fn(),
  }),
}))
vi.mock('vue-router', async () => {
  const { defineComponent } = await import('vue')
  return {
    RouterLink: defineComponent({
      props: ['to'],
      template: '<a><slot /></a>',
    }),
    useRoute: () => ({
      path: '/',
      fullPath: '/',
      query: {},
      meta: {},
    }),
    useRouter: () => ({
      push: routerMocks.push,
    }),
  }
})

import { useAppContext } from '@/composables/useAppContext'
import AppHeader from './AppHeader.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('AppHeader', () => {
  beforeEach(() => {
    Object.values(browseMocks).forEach((mock) => mock.mockReset())
    routerMocks.push.mockReset()
    notificationMocks.refresh.mockReset()
    notificationMocks.connect.mockReset()
    notificationMocks.disconnect.mockReset()
    notificationMocks.markRead.mockReset()
    notificationMocks.state.items = []
    notificationMocks.state.unreadCount = 0
    notificationMocks.state.connected = true
    notificationMocks.state.loading = false
    localStorage.clear()
    useAppContext().setRegion('CN')
  })

  it('reloads current-region hot words and search history after switching region with an empty keyword', async () => {
    browseMocks.fetchHotSearchWords
      .mockResolvedValueOnce([{ term: '火锅', score: 9 }])
      .mockResolvedValueOnce([{ term: 'Brunch', score: 7 }])
    browseMocks.fetchSearchHistory
      .mockResolvedValueOnce({
        list: [
          {
            id: 1,
            keyword: '川菜',
            region: 'CN',
            searchType: 1,
            updatedAt: '2026-07-11 19:30:00',
          },
        ],
        total: 1,
        page: 1,
        pageSize: 6,
        hasMore: false,
      })
      .mockResolvedValueOnce({
        list: [
          {
            id: 2,
            keyword: 'Cafe',
            region: 'EU',
            searchType: 1,
            updatedAt: '2026-07-11 19:31:00',
          },
        ],
        total: 1,
        page: 1,
        pageSize: 6,
        hasMore: false,
      })

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const searchInput = host.querySelector('input[type="search"]')
    expect(searchInput).not.toBeNull()
    searchInput?.dispatchEvent(new FocusEvent('focus'))
    await flushView()

    expect(browseMocks.fetchHotSearchWords).toHaveBeenCalledTimes(1)
    expect(browseMocks.fetchSearchHistory).toHaveBeenCalledWith(1, 6)
    expect(host.textContent).toContain('火锅')
    expect(host.textContent).toContain('川菜')

    useAppContext().setRegion('EU')
    await flushView()

    expect(browseMocks.fetchHotSearchWords).toHaveBeenCalledTimes(2)
    expect(browseMocks.fetchSearchHistory).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('Brunch')
    expect(host.textContent).toContain('Cafe')
    expect(host.textContent).not.toContain('火锅')
    expect(host.textContent).not.toContain('川菜')
    app.unmount()
  })

  it('reloads search suggestions after switching region with the same keyword', async () => {
    browseMocks.fetchSearchSuggestions
      .mockResolvedValueOnce([
        { term: '咖啡', type: 'category', refId: 2 },
        { term: '咖啡馆', type: 'shop', refId: 10002 },
      ])
      .mockResolvedValueOnce([
        { term: 'Coffee', type: 'category', refId: 3 },
        { term: 'Coffee Lab', type: 'shop', refId: 20002 },
      ])

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const searchInput = host.querySelector('input[type="search"]') as HTMLInputElement | null
    expect(searchInput).not.toBeNull()
    searchInput?.dispatchEvent(new FocusEvent('focus'))
    if (searchInput) {
      searchInput.value = '咖啡'
      searchInput.dispatchEvent(new Event('input', { bubbles: true }))
    }
    await flushView()

    expect(browseMocks.fetchSearchSuggestions).toHaveBeenCalledTimes(1)
    expect(browseMocks.fetchSearchSuggestions).toHaveBeenNthCalledWith(1, '咖啡')
    expect(host.textContent).toContain('咖啡馆')

    useAppContext().setRegion('EU')
    await flushView()

    expect(browseMocks.fetchSearchSuggestions).toHaveBeenCalledTimes(2)
    expect(browseMocks.fetchSearchSuggestions).toHaveBeenNthCalledWith(2, '咖啡')
    expect(host.textContent).toContain('Coffee Lab')
    expect(host.textContent).not.toContain('咖啡馆')
    app.unmount()
  })

  it('renders aggregated notifications and keeps direct messages from pushing invalid web routes', async () => {
    notificationMocks.state.items = [
      {
        id: 99,
        type: 'message.direct',
        title: '收到私信',
        content: '阿木：第二条私信提醒',
        linkUrl: '/messages/conversations/33',
        aggregateCount: 2,
        read: false,
        createdAt: '2026-07-21 10:30:00',
      },
    ]
    notificationMocks.state.unreadCount = 2

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    expect(trigger).toBeDefined()
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('收到私信')
    expect(host.textContent).toContain('x2')
    expect(host.textContent).toContain('请在 APP 查看')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    expect(item).not.toBeNull()
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).not.toHaveBeenCalled()
    app.unmount()
  })
})
