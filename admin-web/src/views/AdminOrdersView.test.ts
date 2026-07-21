import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminOrders: vi.fn(),
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: { permissions: ['data:order:read'], region: 'CN' },
  }),
}))

import AdminOrdersView from './AdminOrdersView.vue'

const orders = [
  {
    id: 9301,
    orderNo: 'ADMIN-ORDER-001',
    merchantId: 1001,
    merchantName: '沪上渝里餐饮',
    shopId: 10001,
    shopName: '沪上渝里火锅',
    userId: 9001,
    userNickname: '审评员阿木',
    account: 'demo.cn@example.com',
    dealId: 40001,
    dealTitle: '双人川渝火锅套餐',
    quantity: 2,
    unitPrice: 88,
    amount: 176,
    currency: 'CNY',
    payMethod: 'alipay_mock',
    payStatus: 2,
    payStatusText: '已退款',
    status: 1,
    statusText: '正常',
    paymentChannel: 'alipay_mock',
    paymentChannelTxn: 'TX-ADMIN-001',
    paymentStatus: 1,
    paymentStatusText: '成功',
    paidAt: '2026-07-20 09:00:00',
    createdAt: '2026-07-20 08:30:00',
    paymentCreatedAt: '2026-07-20 08:31:00',
    refundId: 9501,
    refundAmount: 176,
    refundReason: '行程变动',
    refundStatus: 1,
    refundStatusText: '退款成功',
    refundAuditReason: '审核通过',
    refundAuditedAt: '2026-07-20 09:20:00',
    refundCreatedAt: '2026-07-20 09:10:00',
  },
]

async function flush() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mount() {
  const host = document.createElement('div')
  const app = createApp(AdminOrdersView)
  app.mount(host)
  return { app, host }
}

function click(host: HTMLElement, text: string) {
  const button = [...host.querySelectorAll('button')].find((item) => item.textContent?.includes(text))
  if (!button) throw new Error(`missing button: ${text}`)
  button.click()
}

function input(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLInputElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing input: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('input'))
}

function select(host: HTMLElement, name: string, value: string) {
  const element = host.querySelector<HTMLSelectElement>(`[name="${name}"]`)
  if (!element) throw new Error(`missing select: ${name}`)
  element.value = value
  element.dispatchEvent(new Event('change'))
}

describe('AdminOrdersView', () => {
  beforeEach(() => {
    Object.values(mocks).forEach((mock) => mock.mockReset())
    mocks.listAdminOrders.mockResolvedValue({ list: orders, total: 1, page: 1, pageSize: 20, hasMore: false })
  })

  it('loads orders and applies filters', async () => {
    const { app, host } = mount()
    await flush()

    expect(mocks.listAdminOrders).toHaveBeenCalledWith({
      merchantId: undefined,
      shopId: undefined,
      userId: undefined,
      payStatus: undefined,
      refundStatus: undefined,
      orderNo: undefined,
      dateFrom: undefined,
      dateTo: undefined,
      page: 1,
      pageSize: 20,
    })
    expect(host.textContent).toContain('ADMIN-ORDER-001')
    expect(host.textContent).toContain('退款成功')

    input(host, 'admin-order-merchant-id', '1001')
    input(host, 'admin-order-shop-id', '10001')
    input(host, 'admin-order-user-id', '9001')
    select(host, 'admin-order-pay-status', '2')
    select(host, 'admin-order-refund-status', '1')
    input(host, 'admin-order-order-no', 'ADMIN-ORDER-001')
    input(host, 'admin-order-date-from', '2026-07-20')
    input(host, 'admin-order-date-to', '2026-07-20')
    await nextTick()
    click(host, '应用筛选')
    await flush()

    expect(mocks.listAdminOrders).toHaveBeenLastCalledWith({
      merchantId: 1001,
      shopId: 10001,
      userId: 9001,
      payStatus: 2,
      refundStatus: 1,
      orderNo: 'ADMIN-ORDER-001',
      dateFrom: '2026-07-20',
      dateTo: '2026-07-20',
      page: 1,
      pageSize: 20,
    })
    app.unmount()
  })
})
