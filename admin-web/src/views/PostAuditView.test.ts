import { createApp, nextTick } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const adminMocks = vi.hoisted(() => ({
  listAuditTasks: vi.fn(),
  passAuditTask: vi.fn(),
  rejectAuditTask: vi.fn(),
}))

const sessionMock = vi.hoisted(() => ({
  state: undefined as unknown as { region: 'CN' | 'EU'; permissions: string[] },
}))

vi.mock('@/services/admin', () => adminMocks)
vi.mock('@/composables/useAdminSession', async () => {
  const { reactive } = await import('vue')
  sessionMock.state = reactive({
    region: 'EU' as const,
    permissions: ['audit:post:read', 'audit:post:write'],
  })
  return { useAdminSession: () => ({ state: sessionMock.state }) }
})

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
    sessionMock.state.region = 'EU'
    sessionMock.state.permissions = ['audit:post:read', 'audit:post:write']
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
    expect(host.textContent).toContain('Post Audit')
    expect(host.textContent).toContain('伦敦周末市场指南')

    const keyword = host.querySelector<HTMLInputElement>('[data-testid="post-keyword-filter"]')
    if (!keyword) throw new Error('找不到关键词输入框')
    keyword.value = '伦敦'
    keyword.dispatchEvent(new Event('input'))
    const applyButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('Apply filters'))
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

    const passButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('Approve post'))
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

    const rejectButton = [...host.querySelectorAll('button')].find((button) => button.textContent?.includes('Reject post'))
    if (!rejectButton) throw new Error('找不到驳回帖子按钮')
    rejectButton.click()
    await flushView()
    expect(host.textContent).toContain('A rejection reason is required.')
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

  it('keeps list and detail browsing while hiding write controls from read-only users', async () => {
    sessionMock.state.permissions = ['audit:post:read']
    const { app, host } = mountView()
    await flushView()

    expect(adminMocks.listAuditTasks).toHaveBeenCalledTimes(1)
    expect(host.textContent).toContain('伦敦周末市场指南')
    expect(host.textContent).toContain('伦敦小王')
    expect(host.textContent).toContain('This account is read-only and cannot process post audits.')
    expect(host.querySelector('textarea[name="approve-remark"]')).toBeNull()
    expect(host.querySelector('textarea[name="reject-reason"]')).toBeNull()
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Approve post'))).toBe(false)
    expect([...host.querySelectorAll('button')].some((button) => button.textContent?.includes('Reject post'))).toBe(false)
    app.unmount()
  })

  it('blocks mutations through stale buttons after write permission is revoked', async () => {
    const { app, host } = mountView()
    await flushView()

    const passButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Approve post'))
    const rejectButton = [...host.querySelectorAll<HTMLButtonElement>('button')]
      .find((button) => button.textContent?.includes('Reject post'))
    const reason = host.querySelector<HTMLTextAreaElement>('textarea[name="reject-reason"]')
    if (!passButton || !rejectButton || !reason) throw new Error('找不到帖子审核写入控件')
    reason.value = '包含联系方式引流'
    reason.dispatchEvent(new Event('input'))

    sessionMock.state.permissions = ['audit:post:read']
    passButton.click()
    rejectButton.click()
    await flushView()

    expect(adminMocks.passAuditTask).not.toHaveBeenCalled()
    expect(adminMocks.rejectAuditTask).not.toHaveBeenCalled()
    expect(host.querySelector('textarea[name="approve-remark"]')).toBeNull()
    expect(host.querySelector('textarea[name="reject-reason"]')).toBeNull()
    app.unmount()
  })
})
