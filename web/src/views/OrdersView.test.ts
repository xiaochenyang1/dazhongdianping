import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const tradeMocks = vi.hoisted(() => ({
  fetchOrders: vi.fn(),
  cancelOrder: vi.fn(),
  refundOrder: vi.fn(),
}))

const routeState = vi.hoisted(() => ({
  query: {} as Record<string, string | string[] | undefined>,
}))

const routerMocks = vi.hoisted(() => ({
  replace: vi.fn(),
}))

vi.mock('@/services/trade', () => tradeMocks)
vi.mock('@/lib/currency', () => ({
  formatMoney: (amount: number, currency: string) => `${currency} ${amount}`,
}))
vi.mock('vue-router', () => ({
  useRoute: () => routeState,
  useRouter: () => routerMocks,
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path" v-bind="$attrs"><slot /></a>',
  },
}))

import OrdersView from './OrdersView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(OrdersView)
  app.mount(host)
  return { app, host }
}

const unpaidOrder = {
  id: 10,
  orderNo: 'OD-10',
  dealId: 5,
  dealTitle: '双人晚餐套餐',
  shopId: 2,
  shopName: '柏林茶馆',
  coverImage: 'https://example.com/cover.jpg',
  quantity: 1,
  unitPrice: 29.9,
  amount: 29.9,
  currency: 'EUR',
  payStatus: 0,
  payStatusText: '待支付',
  status: 1,
  coupons: [],
}

describe('OrdersView', () => {
  beforeEach(() => {
    tradeMocks.fetchOrders.mockReset()
    tradeMocks.cancelOrder.mockReset()
    tradeMocks.refundOrder.mockReset()
    routerMocks.replace.mockReset()
    routeState.query = {}
    tradeMocks.fetchOrders.mockResolvedValue({
      list: [unpaidOrder],
      total: 1,
      page: 1,
      pageSize: 50,
      hasMore: false,
    })
  })

  it('loads orders with payStatus from query', async () => {
    routeState.query = { payStatus: '0' }
    const { app, host } = mount()
    await flush()

    expect(tradeMocks.fetchOrders).toHaveBeenCalledWith(0, 1, 50)
    expect(host.textContent).toContain('双人晚餐套餐')
    expect(host.textContent).toContain('OD-10')
    expect(host.textContent).toContain('当前筛选：待支付')
    expect(host.querySelector('[data-testid="order-card-10"]')).not.toBeNull()
    app.unmount()
  })

  it('switches payStatus filter via router query', async () => {
    const { app, host } = mount()
    await flush()

    const paidTab = host.querySelector('[data-testid="order-tab-1"]') as HTMLButtonElement | null
    expect(paidTab).not.toBeNull()
    paidTab?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flush()

    expect(routerMocks.replace).toHaveBeenCalledWith({
      path: '/user/orders',
      query: { payStatus: '1' },
    })
    app.unmount()
  })

  it('cancels an unpaid order and reloads the list', async () => {
    tradeMocks.cancelOrder.mockResolvedValue({ ...unpaidOrder, status: 2 })
    const { app, host } = mount()
    await flush()

    const cancelButton = host.querySelector(
      '[data-testid="order-cancel-10"]',
    ) as HTMLButtonElement | null
    expect(cancelButton).not.toBeNull()
    cancelButton?.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    await flush()

    expect(tradeMocks.cancelOrder).toHaveBeenCalledWith(10)
    expect(tradeMocks.fetchOrders).toHaveBeenCalledTimes(2)
    expect(host.textContent).toContain('订单 OD-10 已取消')
    app.unmount()
  })
})
