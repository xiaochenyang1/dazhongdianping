import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAuditTasks: vi.fn(),
  getAdminShopChangeDetail: vi.fn(),
  passAuditTask: vi.fn(),
  rejectAuditTask: vi.fn(),
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({ state: { region: 'EU' } }),
}))

import ShopChangeAuditView from './ShopChangeAuditView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(ShopChangeAuditView)
  app.mount(host)
  return { app, host }
}

function pendingTask() {
  return {
    id: 55,
    bizType: 5,
    bizTypeText: '门店变更',
    bizId: 9001,
    region: 'EU',
    status: 0,
    statusText: '待人审',
    shopId: 20001,
    shopName: 'Maison Sichuan Draft',
    submittedBy: '巴黎川味餐饮',
    summary: '新版门店资料',
    remark: '',
    createdAt: '2026-07-24 12:00:00',
    updatedAt: '2026-07-24 12:00:00',
  }
}

describe('ShopChangeAuditView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    adminMocks.listAuditTasks.mockResolvedValue({
      list: [pendingTask()],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
    adminMocks.getAdminShopChangeDetail.mockResolvedValue({
      id: 9001,
      changeType: 2,
      targetShopId: 20001,
      merchantName: '巴黎川味餐饮',
      categoryId: 201,
      cityId: 101,
      areaId: 1011,
      name: 'Maison Sichuan Draft',
      coverUrl: 'https://files.example/new-cover.jpg',
      phone: '+33142345678',
      pricePerCapita: 42,
      currency: 'EUR',
      address: '18 Rue du Temple, Paris',
      businessHours: '11:30-22:30',
      summary: '新版门店资料',
      openNow: true,
      tags: ['Chinese', 'Spicy'],
      status: 1,
      statusText: '待审核',
      photos: [{ imageUrl: 'https://files.example/new-cover.jpg', photoType: 1, sort: 1 }],
      dishes: [{ name: '水煮鱼', price: 28, recommendReason: '招牌', sort: 1 }],
    })
  })

  it('loads pending shop-change audits and passes the selected task', async () => {
    adminMocks.passAuditTask.mockResolvedValue({ ...pendingTask(), status: 1, statusText: '通过' })
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'EU',
      bizType: 5,
      status: 0,
      page: 1,
      pageSize: 10,
    })
    expect(adminMocks.getAdminShopChangeDetail).toHaveBeenCalledWith(9001)
    expect(host.textContent).toContain('Maison Sichuan Draft')
    expect(host.textContent).toContain('巴黎川味餐饮')
    expect(host.textContent).toContain('水煮鱼')
    expect(host.textContent).toContain('18 Rue du Temple, Paris')

    const passButton = [...host.querySelectorAll('button')].find((button) =>
      button.textContent?.includes('通过门店草稿'),
    )
    if (!passButton) throw new Error('找不到通过门店草稿按钮')
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(55, { remark: undefined })
    app.unmount()
  })

  it('requires a reason and rejects the selected shop-change audit', async () => {
    adminMocks.rejectAuditTask.mockResolvedValue({ ...pendingTask(), status: 2, statusText: '驳回' })
    const { app, host } = mountView()
    await flushView()

    const rejectButton = [...host.querySelectorAll('button')].find((button) =>
      button.textContent?.includes('驳回门店草稿'),
    )
    if (!rejectButton) throw new Error('找不到驳回门店草稿按钮')
    rejectButton.click()
    await flushView()
    expect(host.textContent).toContain('驳回原因不能为空')
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!reason) throw new Error('找不到驳回原因输入框')
    reason.value = '封面与营业执照主体不一致'
    reason.dispatchEvent(new Event('input'))
    rejectButton.click()
    await flushView()

    expect(adminMocks.rejectAuditTask).toHaveBeenCalledWith(55, {
      reason: '封面与营业执照主体不一致',
    })
    app.unmount()
  })
})
