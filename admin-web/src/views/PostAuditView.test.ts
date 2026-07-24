import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAuditTasks: vi.fn(),
  passAuditTask: vi.fn(),
  rejectAuditTask: vi.fn(),
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', () => ({
  useAdminSession: () => ({ state: { region: 'EU' } }),
}))

import PostAuditView from './PostAuditView.vue'

async function flushView() {
  await Promise.resolve()
  await Promise.resolve()
  await nextTick()
}

function mountView() {
  const host = document.createElement('div')
  const app = createApp(PostAuditView)
  app.mount(host)
  return { app, host }
}

function pendingTask() {
  return {
    id: 41,
    bizType: 4,
    bizTypeText: '帖子审核',
    bizId: 7,
    region: 'EU',
    status: 0,
    statusText: '待人审',
    shopId: 0,
    shopName: '',
    submittedBy: '伦敦小王',
    summary: '伦敦周末市场指南：周六上午选择最多。',
    remark: '',
    createdAt: '2026-07-16 10:00:00',
    updatedAt: '2026-07-16 10:00:00',
  }
}

describe('PostAuditView', () => {
  beforeEach(() => {
    Object.values(adminMocks).forEach((mock) => mock.mockReset())
    adminMocks.listAuditTasks.mockResolvedValue({
      list: [pendingTask()],
      total: 1,
      page: 1,
      pageSize: 10,
      hasMore: false,
    })
  })

  it('loads pending post audits and passes the selected task', async () => {
    adminMocks.passAuditTask.mockResolvedValue({ ...pendingTask(), status: 1, statusText: '通过' })
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledWith({
      region: 'EU',
      bizType: 4,
      status: 0,
      keyword: undefined,
      page: 1,
      pageSize: 10,
    })
    expect(host.textContent).toContain('伦敦周末市场指南')

    const keyword = host.querySelector<HTMLInputElement>('[data-testid="post-keyword-filter"]')
    if (!keyword) throw new Error('找不到关键词输入框')
    keyword.value = '伦敦'
    keyword.dispatchEvent(new Event('input'))
    const applyButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('应用筛选'))
    if (!applyButton) throw new Error('找不到应用筛选按钮')
    applyButton.click()
    await flushView()
    expect(adminMocks.listAuditTasks).toHaveBeenLastCalledWith({
      region: 'EU',
      bizType: 4,
      status: 0,
      keyword: '伦敦',
      page: 1,
      pageSize: 10,
    })

    const passButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('通过帖子'))
    if (!passButton) throw new Error('找不到通过帖子按钮')
    passButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).toHaveBeenCalledWith(41, { remark: undefined })
    app.unmount()
  })

  it('requires a reason and rejects the selected post audit', async () => {
    adminMocks.rejectAuditTask.mockResolvedValue({ ...pendingTask(), status: 2, statusText: '驳回' })
    const { app, host } = mountView()
    await flushView()

    const rejectButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('驳回帖子'))
    if (!rejectButton) throw new Error('找不到驳回帖子按钮')
    rejectButton.click()
    await flushView()
    expect(host.textContent).toContain('驳回原因不能为空')
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()

    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!reason) throw new Error('找不到驳回原因输入框')
    reason.value = '包含联系方式引流'
    reason.dispatchEvent(new Event('input'))
    rejectButton.click()
    await flushView()

    expect(adminMocks.rejectAuditTask).toHaveBeenCalledWith(41, { reason: '包含联系方式引流' })
    app.unmount()
  })
})
