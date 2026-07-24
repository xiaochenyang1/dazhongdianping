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
          id: 3,
          type: 'coupon.reminder',
          title: '券码即将过期（1 天内）',
          content: '双人套餐 · 测试火锅 · 有效期至 2026-07-25 · 券码 CPABC123',
          linkUrl: '/user/coupons?status=1&code=CPABC123&remind=1',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-24 15:30:00',
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
      total: 3,
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
    expect(host.textContent).toContain('券码即将过期（1 天内）')
    expect(host.textContent).toContain('券码到期提醒')
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

  it('routes coupon reminder notifications to my coupons page', async () => {
    notificationServiceMocks.fetchNotifications.mockResolvedValueOnce({
      list: [
        {
          id: 9,
          type: 'coupon.reminder',
          title: '券码即将过期（1 天内）',
          content: '双人套餐 · 测试火锅 · 有效期至 2026-07-25 · 券码 CPABC123',
          linkUrl: '/user/coupons?status=1&code=CPABC123&remind=1',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-24 15:30:00',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })

    const { app, host } = mount()
    await flush()

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith({
      path: '/user/coupons',
      query: { status: '1', code: 'CPABC123', remind: '1' },
    })
    app.unmount()
  })

  it('routes refund result notifications to order detail page', async () => {
    notificationServiceMocks.fetchNotifications.mockResolvedValueOnce({
      list: [
        {
          id: 12,
          type: 'order.refund.result',
          title: '退款已通过',
          content: '双人套餐 · 订单 OD123 · 商户已同意退款：符合退款规则',
          linkUrl: '/user/orders/88?refund=approved',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-24 16:30:00',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })

    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('退款已通过')
    expect(host.textContent).toContain('退款结果')

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith('/user/orders/88')
    app.unmount()
  })

  it('routes reservation status notifications to reservation detail page', async () => {
    notificationServiceMocks.fetchNotifications.mockResolvedValueOnce({
      list: [
        {
          id: 15,
          type: 'reservation.status',
          title: '预订已确认',
          content: '巴黎川菜馆 · 2026-07-26 18:30 · 2 人 · 商户已确认你的预订',
          linkUrl: '/user/reservations/33?status=confirmed',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-25 09:00:00',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })

    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('预订已确认')
    expect(host.textContent).toContain('预订状态')

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reservations/33')
    app.unmount()
  })

  it('routes review audit notifications to my review detail page', async () => {
    notificationServiceMocks.fetchNotifications.mockResolvedValueOnce({
      list: [
        {
          id: 21,
          type: 'review.audit.result',
          title: '点评已通过审核',
          content: '沪上渝里 · 你的点评已公开展示：内容正常，允许展示',
          linkUrl: '/user/reviews/55?audit=approved',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-25 10:00:00',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })

    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('点评已通过审核')
    expect(host.textContent).toContain('点评审核')

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reviews/55')
    app.unmount()
  })

  it('routes expert certification notifications to profile page', async () => {
    notificationServiceMocks.fetchNotifications.mockResolvedValueOnce({
      list: [
        {
          id: 22,
          type: 'expert.certification.result',
          title: '达人认证已通过',
          content: '你的本地达人认证已通过，公开资料现可展示达人标识：公开内容稳定',
          linkUrl: '/user/profile?expert=approved',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-25 11:00:00',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })

    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('达人认证已通过')
    expect(host.textContent).toContain('达人认证')

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith('/user/profile')
    app.unmount()
  })

  it('routes post audit notifications to community post detail page', async () => {
    notificationServiceMocks.fetchNotifications.mockResolvedValueOnce({
      list: [
        {
          id: 23,
          type: 'post.audit.result',
          title: '帖子已通过审核',
          content: '《伦敦周末早午餐避坑指南》 已公开：内容真实，可公开',
          linkUrl: '/community/posts/88?audit=approved',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-25 12:00:00',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })

    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('帖子已通过审核')
    expect(host.textContent).toContain('帖子审核')

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith('/community/posts/88')
    app.unmount()
  })

  it('routes coupon verified notifications to coupon detail page', async () => {
    notificationServiceMocks.fetchNotifications.mockResolvedValueOnce({
      list: [
        {
          id: 24,
          type: 'coupon.verified',
          title: '券码已核销',
          content: '双人套餐 · 测试火锅 · 券码 CPABC123 已核销成功',
          linkUrl: '/user/coupons/CPABC123',
          aggregateCount: 1,
          read: false,
          readAt: '',
          createdAt: '2026-07-25 13:00:00',
        },
      ],
      total: 1,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })

    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('券码已核销')
    expect(host.textContent).toContain('券码核销')

    const button = [...host.querySelectorAll('button')].find((el) => el.textContent?.includes('查看详情'))
    button?.click()
    await flush()

    expect(notificationStateMocks.markRead).toHaveBeenCalled()
    expect(routerMocks.push).toHaveBeenCalledWith('/user/coupons/CPABC123')
    app.unmount()
  })
})
