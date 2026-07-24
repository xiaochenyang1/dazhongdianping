import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const notificationServiceMocks = vi.hoisted(() => ({
  fetchNotifications: vi.fn(),
}))

const notificationStateMocks = vi.hoisted(() => ({
  state: {
    items: [] as Array<Record<string, unknown>>,
    unreadCount: 2,
    connected: false,
    loading: false,
  },
  refresh: vi.fn(),
  markRead: vi.fn(),
  markAllRead: vi.fn(),
}))

const routerMocks = vi.hoisted(() => ({
  push: vi.fn(),
}))

vi.mock('@/services/notification', () => notificationServiceMocks)
vi.mock('@/composables/useNotifications', () => ({
  useNotifications: () => notificationStateMocks,
}))
vi.mock('vue-router', () => ({
  useRouter: () => routerMocks,
}))

import NotificationsView from './NotificationsView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(NotificationsView)
  app.mount(host)
  return { app, host }
}

describe('NotificationsView', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    notificationServiceMocks.fetchNotifications.mockReset()
    notificationStateMocks.refresh.mockReset()
    notificationStateMocks.markRead.mockReset()
    notificationStateMocks.markAllRead.mockReset()
    routerMocks.push.mockReset()
    notificationStateMocks.state.unreadCount = 2
    notificationServiceMocks.fetchNotifications.mockResolvedValue({
      list: [
        {
          id: 1,
          type: 'reservation.reminder',
          title: '预订提醒（2 小时）',
          content: '测试门店 · 18:00 · 2 人',
          linkUrl: '/user/reservations/88?remind=120',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-24 16:00:00',
        },
        {
          id: 2,
          type: 'message.direct',
          title: '收到私信',
          content: '你好',
          linkUrl: '/messages/conversations/1',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-24 15:00:00',
        },
      ],
      total: 2,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    notificationStateMocks.markAllRead.mockResolvedValue({ updated: 2, count: 0 })
    notificationStateMocks.markRead.mockImplementation(async (item: { read: boolean }) => {
      item.read = true
    })
  })

  it('loads notifications and marks all as read', async () => {
    const { app, host } = mount()
    await flush()

    expect(notificationServiceMocks.fetchNotifications).toHaveBeenCalledWith(1, 20)
    expect(host.textContent).toContain('预订提醒（2 小时）')
    expect(host.textContent).toContain('收到私信')

    host.querySelector<HTMLButtonElement>('[data-testid="notifications-mark-all"]')?.click()
    await flush()
    expect(notificationStateMocks.markAllRead).toHaveBeenCalled()
    app.unmount()
  })

  it('opens detail route for non-message notifications', async () => {
    const { app, host } = mount()
    await flush()

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reservations/88')
    app.unmount()
  })
})
