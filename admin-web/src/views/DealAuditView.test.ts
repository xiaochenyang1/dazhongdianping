import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAuditTasks: vi.fn(),
  getAdminDealDetail: vi.fn(),
  passAuditTask: vi.fn(),
  rejectAuditTask: vi.fn(),
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({ state: { region: 'EU' } }),
}))

import DealAuditView from './DealAuditView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(DealAuditView)
  app.mount(host)
  return { app, host }
}

function pendingTask() {
  return {
    id: 62,
    bizType: 2,
    bizTypeText: '团购/代金券',
    bizId: 501,
    region: 'EU',
    status: 0,
    statusText: '待人审',
    shopId: 20001,
    shopName: '巴黎川味馆',
    submittedBy: '巴黎川味餐饮',
    summary: '双人午市套餐',
    remark: '',
    createdAt: '2026-07-24 13:00:00',
    updatedAt: '2026-07-24 13:00:00',
  }
}

describe('DealAuditView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    adminMocks.listAuditTasks.mockResolvedValue({
      list: [pendingTask()],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
    adminMocks.getAdminDealDetail.mockResolvedValue({
      id: 501,
      shopId: 20001,
      shopName: '巴黎川味馆',
      type: 1,
      title: '双人午市套餐',
      coverImage: 'https://files.example/deal.jpg',
      price: 49.9,
      originalPrice: 68,
      currency: 'EUR',
      stock: 20,
      validStart: '2026-07-01',
      validEnd: '2026-12-31',
      rules: '周末通用',
      auditStatus: 0,
      auditStatusText: '待审核',
      status: 0,
      statusText: '已下架',
      items: [{ name: '主菜', quantity: 1, price: 30, sort: 1 }],
    })
  })

  it('loads pending deal audits and passes the selected task', async () => {
    adminMocks.passAuditTask.mockResolvedValue({ ...pendingTask(), status: 1, statusText: '通过' })
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'EU',
      bizType: 2,
      status: 0,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(adminMocks.getAdminDealDetail).toHaveBeenCalledWith(501)
    expect(host.textContent).toContain('双人午市套餐')
    expect(host.textContent).toContain('巴黎川味餐饮')
    expect(host.textContent).toContain('主菜')
    expect(host.textContent).toContain('周末通用')

    const keyword = host.querySelector<HTMLInputElement>('[data-testid="deal-keyword-filter"]')
    if (!keyword) throw new Error('找不到关键词输入框')
    keyword.value = '巴黎川味'
    keyword.dispatchEvent(new Event('input'))
    const applyButton = [...host.querySelectorAll('button')].find((button) =>
      button.textContent?.includes('应用筛选'),
    )
    if (!applyButton) throw new Error('找不到应用筛选按钮')
    applyButton.click()
    await flushView()
    expect(adminMocks.listAuditTasks).toHaveBeenLastCalledWith({
      region: 'EU',
      bizType: 2,
      status: 0,
      keyword: '巴黎川味',
      page: 1,
      pageSize: 10,
    })

    const passButton = [...host.querySelectorAll('button')].find((button) =>
      button.textContent?.includes('通过团购'),
    )
    if (!passButton) throw new Error('找不到通过团购按钮')
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(62, { remark: undefined })
    app.unmount()
  })

  it('requires a reason and rejects the selected deal audit', async () => {
    adminMocks.rejectAuditTask.mockResolvedValue({ ...pendingTask(), status: 2, statusText: '驳回' })
    const { app, host } = mountView()
    await flushView()

    const rejectButton = [...host.querySelectorAll('button')].find((button) =>
      button.textContent?.includes('驳回团购'),
    )
    if (!rejectButton) throw new Error('找不到驳回团购按钮')
    rejectButton.click()
    await flushView()
    expect(host.textContent).toContain('驳回原因不能为空')
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!reason) throw new Error('找不到驳回原因输入框')
    reason.value = '价格与规则描述不一致'
    reason.dispatchEvent(new Event('input'))
    rejectButton.click()
    await flushView()

    expect(adminMocks.rejectAuditTask).toHaveBeenCalledWith(62, {
      reason: '价格与规则描述不一致',
    })
    app.unmount()
  })
})
