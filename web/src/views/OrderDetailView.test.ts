import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const tradeMocks = vi.hoisted(() => ({
  fetchOrder: vi.fn(),
  payOrder: vi.fn(),
  completeMockPayment: vi.fn(),
  cancelOrder: vi.fn(),
  refundOrder: vi.fn(),
}))

const stripeCheckoutMock = vi.hoisted(() => ({
  state: {
    error: { value: '' },
    processing: { value: false },
    ready: { value: true },
  },
  mount: vi.fn(async (_el: HTMLElement, _secret: string) => {}),
  confirm: vi.fn(async () => true),
  unmount: vi.fn(),
}))

const routeState = vi.hoisted(() => ({
  query: {} as Record<string, string>,
}))

vi.mock('@/services/trade', () => tradeMocks)
vi.mock('@/composables/useStripeCheckout', () => ({
  useStripeCheckout: () => ({
    error: stripeCheckoutMock.state.error,
    processing: stripeCheckoutMock.state.processing,
    ready: stripeCheckoutMock.state.ready,
    mount: stripeCheckoutMock.mount,
    confirm: stripeCheckoutMock.confirm,
    unmount: stripeCheckoutMock.unmount,
  }),
}))
vi.mock('vue-router', () => ({
  useRoute: () => routeState,
  RouterLink: {
    props: ['to'],
    template: '<a :href="typeof to === \'string\' ? to : to.path"><slot /></a>',
  },
}))

import OrderDetailView from './OrderDetailView.vue'

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
  await Promise.resolve()
  await nextTick()
}

function mount(orderId = 88) {
  const host = document.createElement('div')
  const app = createApp(OrderDetailView, { orderId })
  app.mount(host)
  return { app, host }
}

describe('OrderDetailView', () => {
  beforeEach(() => {
    Object.values(tradeMocks).forEach((mock) => mock.mockReset())
    stripeCheckoutMock.mount.mockClear()
    stripeCheckoutMock.confirm.mockClear()
    stripeCheckoutMock.unmount.mockClear()
    stripeCheckoutMock.state.error.value = ''
    stripeCheckoutMock.state.processing.value = false
    stripeCheckoutMock.state.ready.value = true
    routeState.query = {}
    tradeMocks.fetchOrder.mockResolvedValue({
      id: 88,
      orderNo: 'OD123',
      dealId: 40001,
      dealTitle: '双人套餐',
      shopId: 10001,
      shopName: '测试火锅',
      coverImage: 'https://example.com/cover.jpg',
      quantity: 1,
      unitPrice: 88,
      amount: 88,
      currency: 'CNY',
      payStatus: 1,
      payStatusText: '已支付',
      status: 1,
      coupons: [
        {
          id: 1,
          orderId: 88,
          code: 'CPABC123',
          status: 1,
          statusText: '待使用',
          dealId: 40001,
          dealTitle: '双人套餐',
          shopId: 10001,
          shopName: '测试火锅',
          coverImage: '',
          expireAt: '2026-12-31',
        },
      ],
    })
    window.prompt = vi.fn()
    window.confirm = vi.fn()
  })

  it('loads paid order and submits refund application', async () => {
    window.prompt = vi.fn().mockReturnValue('行程有变')
    tradeMocks.refundOrder.mockResolvedValue({
      id: 88,
      orderNo: 'OD123',
      dealId: 40001,
      dealTitle: '双人套餐',
      shopId: 10001,
      shopName: '测试火锅',
      coverImage: '',
      quantity: 1,
      unitPrice: 88,
      amount: 88,
      currency: 'CNY',
      payStatus: 1,
      payStatusText: '已支付',
      status: 1,
      refund: {
        id: 9,
        amount: 88,
        reason: '行程有变',
        status: 0,
        statusText: '申请中',
        createdAt: '2026-07-24 12:00:00',
      },
      coupons: [],
    })

    const { app, host } = mount()
    await flush()

    expect(tradeMocks.fetchOrder).toHaveBeenCalledWith(88)
    expect(host.textContent).toContain('双人套餐')
    expect(host.querySelector('[data-testid="order-coupon-link-CPABC123"]')?.getAttribute('href')).toBe(
      '/user/coupons/CPABC123',
    )

    host.querySelector<HTMLButtonElement>('[data-testid="order-refund"]')?.click()
    await flush()

    expect(tradeMocks.refundOrder).toHaveBeenCalledWith(88, '行程有变')
    expect(host.textContent).toContain('退款进度')
    expect(host.textContent).toContain('申请中')
    app.unmount()
  })

  it('shows refund result banner from notification query', async () => {
    routeState.query = { refund: 'approved' }
    tradeMocks.fetchOrder.mockResolvedValue({
      id: 88,
      orderNo: 'OD123',
      dealId: 40001,
      dealTitle: '双人套餐',
      shopId: 10001,
      shopName: '测试火锅',
      coverImage: '',
      quantity: 1,
      unitPrice: 88,
      amount: 88,
      currency: 'CNY',
      payStatus: 2,
      payStatusText: '已退款',
      status: 1,
      refund: {
        id: 9,
        amount: 88,
        reason: '行程有变',
        status: 1,
        statusText: '退款成功',
        auditReason: '符合规则',
        auditedAt: '2026-07-24 13:00:00',
        createdAt: '2026-07-24 12:00:00',
      },
    })

    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('退款已通过，订单状态已更新。')
    expect(host.textContent).toContain('符合规则')
    app.unmount()
  })

  function unpaidOrder() {
    return {
      id: 88,
      orderNo: 'OD123',
      dealId: 40001,
      dealTitle: '双人套餐',
      shopId: 10001,
      shopName: '测试火锅',
      coverImage: '',
      quantity: 1,
      unitPrice: 88,
      amount: 88,
      currency: 'CNY',
      payStatus: 0,
      payStatusText: '待支付',
      status: 1,
      coupons: [],
    }
  }

  it('shows the card form and hides mock-complete when clientSecret is present', async () => {
    tradeMocks.fetchOrder.mockResolvedValue(unpaidOrder())
    tradeMocks.payOrder.mockResolvedValue({
      paymentId: 1, channel: 'stripe', channelTxn: 'pi_1',
      clientSecret: 'pi_1_secret_abc', orderNo: 'OD123', amount: 88, currency: 'CNY',
    })

    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="order-pay"]')?.click()
    await flush()

    expect(stripeCheckoutMock.mount).toHaveBeenCalled()
    expect(stripeCheckoutMock.mount.mock.calls[0][1]).toBe('pi_1_secret_abc')
    expect(host.querySelector('[data-testid="stripe-card-element"]')).not.toBeNull()
    expect(host.querySelector('[data-testid="mock-pay-complete"]')).toBeNull()
    app.unmount()
  })

  it('keeps the mock-complete button when clientSecret is empty', async () => {
    tradeMocks.fetchOrder.mockResolvedValue(unpaidOrder())
    tradeMocks.payOrder.mockResolvedValue({
      paymentId: 1, channel: 'alipay_mock', channelTxn: 'TX1',
      clientSecret: '', orderNo: 'OD123', amount: 88, currency: 'CNY',
    })

    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="order-pay"]')?.click()
    await flush()

    expect(stripeCheckoutMock.mount).not.toHaveBeenCalled()
    expect(host.querySelector('[data-testid="mock-pay-complete"]')).not.toBeNull()
    expect(host.querySelector('[data-testid="stripe-card-element"]')).toBeNull()
    app.unmount()
  })

  it('confirms the card and reloads the order on success', async () => {
    tradeMocks.fetchOrder.mockResolvedValue(unpaidOrder())
    tradeMocks.payOrder.mockResolvedValue({
      paymentId: 1, channel: 'stripe', channelTxn: 'pi_1',
      clientSecret: 'pi_1_secret_abc', orderNo: 'OD123', amount: 88, currency: 'CNY',
    })

    const { app, host } = mount()
    await flush()

    host.querySelector<HTMLButtonElement>('[data-testid="order-pay"]')?.click()
    await flush()
    host.querySelector<HTMLButtonElement>('[data-testid="stripe-pay-confirm"]')?.click()
    await flush()

    expect(stripeCheckoutMock.confirm).toHaveBeenCalled()
    expect(stripeCheckoutMock.unmount).toHaveBeenCalled()
    expect(host.textContent).toContain('正在确认支付结果')
    expect(host.querySelector('[data-testid="stripe-card-element"]')).toBeNull()
    app.unmount()
  })
})
