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

  it('routes reservation reminder notifications to the reservation detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 101,
        type: 'reservation.reminder',
        title: '预订即将开始（30 分钟）',
        content: '测试门店 · 2026-07-24 18:30 · 2 人',
        linkUrl: '/user/reservations/88?remind=30',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-24 18:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('预订即将开始（30 分钟）')
    expect(host.textContent).toContain('预订提醒')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reservations/88')
    app.unmount()
  })

  it('routes coupon reminder notifications to my coupons page', async () => {
    notificationMocks.state.items = [
      {
        id: 202,
        type: 'coupon.reminder',
        title: '券码即将过期（1 天内）',
        content: '双人套餐 · 测试火锅 · 有效期至 2026-07-25 · 券码 CPABC123',
        linkUrl: '/user/coupons?status=1&code=CPABC123&remind=1',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-24 18:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('券码即将过期（1 天内）')
    expect(host.textContent).toContain('券码到期提醒')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith({
      path: '/user/coupons',
      query: { status: '1', code: 'CPABC123', remind: '1' },
    })
    app.unmount()
  })

  it('routes refund result notifications to order detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 303,
        type: 'order.refund.result',
        title: '退款已驳回',
        content: '双人套餐 · 订单 OD123 · 商户已驳回退款：已超过退款时限',
        linkUrl: '/user/orders/88?refund=rejected',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-24 19:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('退款已驳回')
    expect(host.textContent).toContain('退款结果')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/orders/88')
    app.unmount()
  })

  it('routes payment success notifications to order detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 305,
        type: 'order.paid',
        title: '支付成功',
        content: '双人套餐 · 订单 OD456 · 88.00 CNY · 券码已发放，可在我的券查看',
        linkUrl: '/user/orders/99?paid=1',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 10:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('支付成功')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/orders/99')
    app.unmount()
  })

  it('routes reservation created notifications to reservation detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 306,
        type: 'reservation.created',
        title: '预订已自动确认',
        content: '巴黎川菜馆 · 2026-07-26 18:00 · 2 人 · 系统已自动确认你的预订',
        linkUrl: '/user/reservations/44?status=confirmed',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 11:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('预订已自动确认')
    expect(host.textContent).toContain('预订创建')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reservations/44')
    app.unmount()
  })

  it('routes reservation status notifications to reservation detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 404,
        type: 'reservation.status',
        title: '预订已确认',
        content: '巴黎川菜馆 · 2026-07-26 18:30 · 2 人 · 商户已确认你的预订',
        linkUrl: '/user/reservations/33?status=confirmed',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 09:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('预订已确认')
    expect(host.textContent).toContain('预订状态')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reservations/33')
    app.unmount()
  })

  it('routes review audit notifications to my review detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 505,
        type: 'review.audit.result',
        title: '点评未通过审核',
        content: '沪上渝里 · 你的点评未通过审核：内容太敷衍',
        linkUrl: '/user/reviews/55?audit=rejected',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 10:30:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('点评未通过审核')
    expect(host.textContent).toContain('点评审核')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reviews/55')
    app.unmount()
  })

  it('routes expert certification notifications to profile page', async () => {
    notificationMocks.state.items = [
      {
        id: 606,
        type: 'expert.certification.result',
        title: '达人认证已通过',
        content: '你的本地达人认证已通过，公开资料现可展示达人标识',
        linkUrl: '/user/profile?expert=approved',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 11:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('达人认证已通过')
    expect(host.textContent).toContain('达人认证')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/profile')
    app.unmount()
  })

  it('routes post audit notifications to community post detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 707,
        type: 'post.audit.result',
        title: '帖子未通过审核',
        content: '《巴黎租房避坑》 未通过审核：缺少可验证的具体信息',
        linkUrl: '/community/posts/99?audit=rejected',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 12:30:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('帖子未通过审核')
    expect(host.textContent).toContain('帖子审核')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/community/posts/99')
    app.unmount()
  })

  it('routes coupon verified notifications to coupon detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 808,
        type: 'coupon.verified',
        title: '券码已核销',
        content: '双人套餐 · 测试火锅 · 券码 CPABC123 已核销成功',
        linkUrl: '/user/coupons/CPABC123',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 13:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('券码已核销')
    expect(host.textContent).toContain('券码核销')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/coupons/CPABC123')
    app.unmount()
  })

  it('routes review hidden notifications to my review detail page', async () => {
    notificationMocks.state.items = [
      {
        id: 909,
        type: 'review.hidden',
        title: '点评已被隐藏',
        content: '巴黎川菜馆 · 商户申诉成立，你的点评已从公开展示中隐藏：申诉成立',
        linkUrl: '/user/reviews/66?hidden=appeal',
        aggregateCount: 1,
        read: false,
        createdAt: '2026-07-25 14:00:00',
      },
    ]
    notificationMocks.state.unreadCount = 1

    const host = document.createElement('div')
    const app = createApp(AppHeader)
    app.mount(host)
    await flushView()

    const trigger = [...host.querySelectorAll('button')].find((element) => element.textContent?.includes('通知'))
    trigger?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(host.textContent).toContain('点评已被隐藏')
    expect(host.textContent).toContain('点评处理')

    const item = host.querySelector('.notification-item') as HTMLButtonElement | null
    item?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flushView()

    expect(notificationMocks.markRead).toHaveBeenCalledTimes(1)
    expect(routerMocks.push).toHaveBeenCalledWith('/user/reviews/66')
    app.unmount()
  })
})
