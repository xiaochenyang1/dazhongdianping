import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const authMocks = vi.hoisted(() => ({
  fetchCurrentUser: vi.fn(),
  fetchUserGrowthRecords: vi.fn(),
}))
const sessionMocks = vi.hoisted(() => ({
  setCurrentUser: vi.fn(),
}))

vi.mock('@/services/auth', () => authMocks)
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => ({
    state: {
      currentUser: undefined,
    },
    setCurrentUser: sessionMocks.setCurrentUser,
  }),
}))

import UserGrowthRecordsView from './UserGrowthRecordsView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

describe('UserGrowthRecordsView', () => {
  beforeEach(() => {
    Object.values(authMocks).forEach((mock) => mock.mockReset())
    Object.values(sessionMocks).forEach((mock) => mock.mockReset())
  })

  it('renders growth records and refreshes the current user summary', async () => {
    authMocks.fetchCurrentUser.mockResolvedValue({
      id: 9001,
      nickname: '阿评',
      avatar: '',
      email: 'demo.cn@example.com',
      phone: null,
      hasPassword: true,
      gender: 0,
      signature: '能吃会写',
      preferredRegion: 'CN',
      level: 4,
      points: 155,
      growthValue: 120,
    })
    authMocks.fetchUserGrowthRecords.mockResolvedValue({
      list: [
        {
          id: 1,
          type: 1,
          typeText: '成长值',
          action: 'review_create',
          actionText: '发布点评',
          bizId: 701,
          changeAmount: 10,
          balanceAfter: 120,
          remark: '发布点评奖励',
          createdAt: '2026-07-11 18:00:00',
        },
        {
          id: 2,
          type: 2,
          typeText: '积分',
          action: 'review_create',
          actionText: '发布点评',
          bizId: 701,
          changeAmount: 5,
          balanceAfter: 155,
          remark: '发布点评奖励',
          createdAt: '2026-07-11 18:00:01',
        },
      ],
      total: 2,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })

    const host = document.createElement('div')
    const app = createApp(UserGrowthRecordsView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(authMocks.fetchCurrentUser).toHaveBeenCalledTimes(1)
    expect(authMocks.fetchUserGrowthRecords).toHaveBeenCalledWith({ page: 1, pageSize: 10 })
    expect(sessionMocks.setCurrentUser).toHaveBeenCalledWith(
      expect.objectContaining({
        level: 4,
        points: 155,
        growthValue: 120,
      }),
    )
    expect(host.textContent).toContain('Lv.4')
    expect(host.textContent).toContain('155 / 120')
    expect(host.textContent).toContain('成长值 +10')
    expect(host.textContent).toContain('发布点评奖励')
    expect(host.textContent).toContain('业务 #701')
    app.unmount()
  })

  it('shows an empty-state hint when there are no growth records yet', async () => {
    authMocks.fetchCurrentUser.mockResolvedValue({
      id: 9001,
      nickname: '阿评',
      avatar: '',
      email: 'demo.cn@example.com',
      phone: null,
      hasPassword: true,
      gender: 0,
      signature: '能吃会写',
      preferredRegion: 'CN',
      level: 1,
      points: 0,
      growthValue: 0,
    })
    authMocks.fetchUserGrowthRecords.mockResolvedValue({
      list: [],
      total: 0,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })

    const host = document.createElement('div')
    const app = createApp(UserGrowthRecordsView)
    app.component('RouterLink', RouterLinkStub)
    app.mount(host)
    await flushView()

    expect(host.textContent).toContain('现在还没有流水')
    app.unmount()
  })
})
