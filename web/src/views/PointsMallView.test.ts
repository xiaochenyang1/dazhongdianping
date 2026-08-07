import { createApp, defineComponent, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { useAppContext } from '@/composables/useAppContext'

const pointsMocks = vi.hoisted(() => ({
  exchangePointsProduct: vi.fn(),
  fetchMyPointsExchanges: vi.fn(),
  fetchPointsProducts: vi.fn(),
}))

const authMocks = vi.hoisted(() => ({
  fetchCurrentUser: vi.fn(),
}))

const sessionMocks = vi.hoisted(() => ({
  state: {
    currentUser: {
      id: 9001,
      nickname: '阿评',
      preferredRegion: 'CN',
      level: 3,
      points: 120,
      growthValue: 202,
    } as Record<string, unknown> | null,
  },
  setCurrentUser: vi.fn((user: Record<string, unknown>) => {
    sessionMocks.state.currentUser = user
  }),
}))

vi.mock('@/services/points', () => pointsMocks)
vi.mock('@/services/auth', () => authMocks)
vi.mock('@/composables/useUserSession', () => ({
  useUserSession: () => sessionMocks,
}))

import PointsMallView from './PointsMallView.vue'

const RouterLinkStub = defineComponent({
  props: ['to'],
  template: '<a><slot /></a>',
})

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(PointsMallView)
  app.component('RouterLink', RouterLinkStub)
  app.mount(host)
  return { app, host }
}

function product(overrides: Record<string, unknown> = {}) {
  return {
    id: 11,
    region: 'CN',
    name: '咖啡兑换券',
    coverImage: '',
    description: '门店饮品兑换',
    pointsPrice: 50,
    stock: 8,
    exchangeLimitPerUser: 2,
    exchangeCount: 0,
    fulfillType: 1,
    fulfillTypeText: '自动发放',
    status: 1,
    sort: 10,
    soldOut: false,
    createdAt: '2026-08-01 10:00:00',
    updatedAt: '2026-08-01 10:00:00',
    ...overrides,
  }
}

function productPage(list = [product()]) {
  return {
    list,
    total: list.length,
    page: 1,
    pageSize: 12,
    hasMore: false,
  }
}

function exchange(overrides: Record<string, unknown> = {}) {
  return {
    id: 77,
    productId: 11,
    productName: '咖啡兑换券',
    pointsCost: 50,
    quantity: 1,
    status: 1,
    statusText: '已发放',
    redeemCode: 'CODE-77',
    remark: '',
    fulfilledAt: '2026-08-06 11:00:00',
    createdAt: '2026-08-06 10:00:00',
    ...overrides,
  }
}

describe('PointsMallView', () => {
  beforeEach(() => {
    Object.values(pointsMocks).forEach((mock) => mock.mockReset())
    authMocks.fetchCurrentUser.mockReset()
    sessionMocks.setCurrentUser.mockReset()
    sessionMocks.state.currentUser = {
      id: 9001,
      nickname: '阿评',
      preferredRegion: 'CN',
      level: 3,
      points: 120,
      growthValue: 202,
    }
    useAppContext().setRegion('CN')
    vi.spyOn(window, 'confirm').mockReturnValue(true)

    pointsMocks.fetchPointsProducts.mockResolvedValue(productPage())
    pointsMocks.fetchMyPointsExchanges.mockResolvedValue({
      list: [exchange()],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
    pointsMocks.exchangePointsProduct.mockResolvedValue(exchange({ status: 0, statusText: '待发放', redeemCode: '' }))
    authMocks.fetchCurrentUser.mockResolvedValue({
      id: 9001,
      nickname: '阿评',
      preferredRegion: 'CN',
      level: 3,
      points: 120,
      growthValue: 202,
    })
  })

  it('loads the catalog and balance, then exchanges a product', async () => {
    authMocks.fetchCurrentUser
      .mockResolvedValueOnce({
        id: 9001,
        nickname: '阿评',
        preferredRegion: 'CN',
        level: 3,
        points: 120,
        growthValue: 202,
      })
      .mockResolvedValueOnce({
        id: 9001,
        nickname: '阿评',
        preferredRegion: 'CN',
        level: 3,
        points: 70,
        growthValue: 202,
      })

    const { app, host } = mount()
    await flushView()

    expect(pointsMocks.fetchPointsProducts).toHaveBeenCalledWith({ page: 1, pageSize: 12 })
    expect(host.textContent).toContain('积分商城')
    expect(host.querySelector('[data-testid="points-balance"]')?.textContent).toContain('120')
    expect(host.textContent).toContain('咖啡兑换券')

    ;(host.querySelector('[data-testid="points-exchange-11"]') as HTMLButtonElement).click()
    await flushView()

    expect(window.confirm).toHaveBeenCalled()
    expect(pointsMocks.exchangePointsProduct).toHaveBeenCalledWith(11)
    expect(authMocks.fetchCurrentUser).toHaveBeenCalled()
    expect(sessionMocks.setCurrentUser).toHaveBeenCalledWith(expect.objectContaining({ points: 70 }))
    expect(host.querySelector('[data-testid="points-success"]')?.textContent).toContain('兑换成功')
    expect(host.querySelector('[data-testid="points-balance"]')?.textContent).toContain('70')
    app.unmount()
  })

  it('loads exchanges lazily when switching tabs and shows redeem codes only when fulfilled', async () => {
    const { app, host } = mount()
    await flushView()

    expect(pointsMocks.fetchMyPointsExchanges).not.toHaveBeenCalled()

    ;(host.querySelector('[data-testid="points-tab-exchanges"]') as HTMLButtonElement).click()
    await flushView()

    expect(pointsMocks.fetchMyPointsExchanges).toHaveBeenCalledWith({ page: 1, pageSize: 10 })
    expect(host.textContent).toContain('我的兑换')
    expect(host.querySelector('[data-testid="points-redeem-code"]')?.textContent).toContain('CODE-77')
    app.unmount()
  })

  it('disables exchange when points are insufficient and localizes backend errors in English', async () => {
    sessionMocks.state.currentUser = {
      id: 9001,
      nickname: 'Alex',
      preferredRegion: 'EU',
      level: 2,
      points: 10,
      growthValue: 20,
    }
    useAppContext().setRegion('EU')
    pointsMocks.fetchPointsProducts.mockResolvedValue(productPage([product({ pointsPrice: 50 })]))
    authMocks.fetchCurrentUser.mockResolvedValue({
      id: 9001,
      nickname: 'Alex',
      preferredRegion: 'EU',
      level: 2,
      points: 10,
      growthValue: 20,
    })
    pointsMocks.exchangePointsProduct.mockRejectedValue(new Error('积分不足 [traceId: pts-1]'))

    const { app, host } = mount()
    await flushView()

    expect(host.textContent).toContain('Points mall')
    const expensiveButton = host.querySelector('[data-testid="points-exchange-11"]') as HTMLButtonElement
    expect(expensiveButton.disabled).toBe(true)
    expect(host.textContent).toContain('Not enough points for this product.')

    // Remount with enough points to hit API error path
    app.unmount()
    sessionMocks.state.currentUser = {
      id: 9001,
      nickname: 'Alex',
      preferredRegion: 'EU',
      level: 2,
      points: 200,
      growthValue: 20,
    }
    authMocks.fetchCurrentUser.mockResolvedValue({
      id: 9001,
      nickname: 'Alex',
      preferredRegion: 'EU',
      level: 2,
      points: 200,
      growthValue: 20,
    })
    const second = mount()
    await flushView()
    ;(second.host.querySelector('[data-testid="points-exchange-11"]') as HTMLButtonElement).click()
    await flushView()

    expect(second.host.querySelector('[data-testid="points-product-error"]')?.textContent).toContain(
      'You do not have enough points. [traceId: pts-1]',
    )
    expect(second.host.textContent).not.toContain('积分不足')
    second.app.unmount()
  })

  it('skips exchange when the user cancels confirmation', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const { app, host } = mount()
    await flushView()

    ;(host.querySelector('[data-testid="points-exchange-11"]') as HTMLButtonElement).click()
    await flushView()

    expect(pointsMocks.exchangePointsProduct).not.toHaveBeenCalled()
    app.unmount()
  })
})
