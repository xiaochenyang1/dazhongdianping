import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  listAdminOrders: vi.fn(),
  auditAdminOrderRefund: vi.fn(),
  reconcileAdminOrders: vi.fn(),
}))

vi.mock('@/services/admin', () => mocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({
    state: { permissions: ['data:order:read', 'data:order:write'], region: 'CN' },
    hasPermission: (permission: string) => ['data:order:read', 'data:order:write'].includes(permission),
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
  {
    id: 9302,
    orderNo: 'ADMIN-ORDER-002',
    merchantId: 1001,
    merchantName: '沪上渝里餐饮',
    shopId: 10001,
    shopName: '沪上渝里火锅',
    userId: 9002,
    userNickname: '欧洲咖啡客',
    account: 'demo.eu@example.com',
    dealId: 40001,
    dealTitle: '双人川渝火锅套餐',
    quantity: 1,
    unitPrice: 88,
    amount: 88,
    currency: 'CNY',
    payMethod: 'alipay_mock',
    payStatus: 1,
    payStatusText: '已支付',
    status: 1,
    statusText: '正常',
    paymentChannel: 'alipay_mock',
    paymentChannelTxn: 'TX-ADMIN-002',
    paymentStatus: 1,
    paymentStatusText: '成功',
    paidAt: '2026-07-21 10:10:00',
    createdAt: '2026-07-21 10:00:00',
    paymentCreatedAt: '2026-07-21 10:01:00',
    refundId: 9502,
    refundAmount: 88,
    refundReason: '临时有事',
    refundStatus: 0,
    refundStatusText: '申请中',
    refundAuditReason: '',
    refundAuditedAt: '',
    refundCreatedAt: '2026-07-21 11:00:00',
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
    mocks.listAdminOrders.mockResolvedValue({ list: orders, total: 2, page: 1, pageSize: 20, hasMore: false })
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

  it('audits a pending refund and updates the row', async () => {
    mocks.auditAdminOrderRefund.mockResolvedValue({
      ...orders[1],
      payStatus: 2,
      payStatusText: '已退款',
      refundStatus: 1,
      refundStatusText: '退款成功',
      refundAuditReason: '平台仲裁退款',
    })
    const { app, host } = mount()
    await flush()

    expect(host.textContent).toContain('退款仲裁')
    click(host, '退款仲裁')
    await nextTick()

    click(host, '通过退款')
    await flush()
    expect(mocks.auditAdminOrderRefund).not.toHaveBeenCalled()
    expect(host.textContent).toContain('退款仲裁必须填写原因')

    const reasonInput = host.querySelector<HTMLTextAreaElement>('[name="admin-refund-audit-reason"]')
    if (!reasonInput) throw new Error('missing audit reason textarea')
    reasonInput.value = '平台仲裁退款'
    reasonInput.dispatchEvent(new Event('input'))
    await nextTick()

    click(host, '通过退款')
    await flush()

    expect(mocks.auditAdminOrderRefund).toHaveBeenCalledWith(9302, {
      decision: 'approve',
      reason: '平台仲裁退款',
    })
    expect(host.textContent).toContain('订单 ADMIN-ORDER-002 退款已通过')
    expect(host.textContent).toContain('退款成功')
    expect(host.textContent).toContain('无待处理退款')
    app.unmount()
  })

  it('runs trade reconcile compensation', async () => {
    mocks.reconcileAdminOrders.mockResolvedValue({
      closedOrders: 2,
      restoredStockOrders: 2,
      failedPayments: 1,
    })
    const { app, host } = mount()
    await flush()

    click(host, '执行对账补偿')
    await flush()

    expect(mocks.reconcileAdminOrders).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('关闭超时未支付订单 2 笔')
    expect(host.textContent).toContain('标记失败支付流水 1 笔')
    expect(mocks.listAdminOrders).toHaveBeenCalledTimes(2)
    app.unmount()
  })
})
