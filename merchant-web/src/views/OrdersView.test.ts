import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  fetchOrders: vi.fn(),
  auditRefund: vi.fn(),
}))

vi.mock('@/services/merchant', () => mocks)

import OrdersView from './OrdersView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView(permissions = ['order:view', 'order:refund']) {
  const host = document.createElement('div')
  const app = createApp(OrdersView, { permissions })
  app.mount(host)
  return { app, host }
}

describe('OrdersView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.fetchOrders.mockResolvedValue({
      list: [
        {
          id: 81,
          orderNo: 'ORD-81',
          shopName: '巴黎川味馆',
          amount: 36,
          currency: 'EUR',
          payStatusText: '已支付',
          refund: { status: 0, statusText: '申请中' },
        },
        {
          id: 82,
          orderNo: 'ORD-82',
          shopName: '巴黎川味馆',
          amount: 18,
          currency: 'EUR',
          payStatusText: '已退款',
          refund: { status: 1, statusText: '退款成功' },
        },
      ],
      total: 2,
      page: 1,
      pageSize: 20,
      hasMore: false,
    })
    mocks.auditRefund.mockResolvedValue({})
  })

  it('only exposes refund actions for pending applications and sends a reason', async () => {
    const { app, host } = mountView()
    await flushView()

    expect(host.querySelector('[data-testid="refund-actions-81"]')).not.toBeNull()
    expect(host.querySelector('[data-testid="refund-actions-82"]')).toBeNull()

    const reason = host.querySelector<HTMLInputElement>('[name="refund-reason-81"]')
    if (!reason) throw new Error('missing refund reason')
    reason.value = '已核对订单与退款凭证'
    reason.dispatchEvent(new Event('input'))
    host.querySelector<HTMLButtonElement>('[data-testid="approve-refund-81"]')?.click()
    await flushView()

    expect(mocks.auditRefund).toHaveBeenCalledWith(81, 'approve', '已核对订单与退款凭证')
    app.unmount()
  })

  it('requires an audit reason before submitting a refund decision', async () => {
    const { app, host } = mountView()
    await flushView()
    host.querySelector<HTMLButtonElement>('[data-testid="reject-refund-81"]')?.click()
    await nextTick()

    expect(host.textContent).toContain('请填写退款审核原因')
    expect(mocks.auditRefund).not.toHaveBeenCalled()
    app.unmount()
  })

  it('hides refund controls without order:refund permission', async () => {
    const { app, host } = mountView(['order:view'])
    await flushView()

    expect(host.querySelector('[data-testid="refund-actions-81"]')).toBeNull()
    expect(host.querySelector('[data-testid="approve-refund-81"]')).toBeNull()
    expect(mocks.auditRefund).not.toHaveBeenCalled()
    app.unmount()
  })
})
